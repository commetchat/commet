import 'dart:convert';
import 'dart:ui';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_attachment.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/utils/gif_search/gif_search_result.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart' as mx_markdown;

import '../attachment.dart';
import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'components/emoticon/matrix_emoticon_pack.dart';

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  @override
  late final MatrixRoomEmoticonComponent roomEmoticons;

  @override
  bool get isMember => _matrixRoom.membership == matrix.Membership.join;

  @override
  bool get isE2EE => _matrixRoom.encrypted;

  @override
  int get highlightedNotificationCount => _matrixRoom.highlightCount;

  @override
  int get notificationCount => _matrixRoom.notificationCount;

  matrix.Room get matrixRoom => _matrixRoom;

  @override
  TimelineEvent? get lastEvent => _matrixRoom.lastEvent != null
      ? timeline?.tryGetEvent(_matrixRoom.lastEvent!.eventId)
      : timeline?.events.isNotEmpty == true
          ? timeline!.events[0]
          : null;

  @override
  Iterable<String> get memberIds =>
      _matrixRoom.getParticipants().map((e) => e.id);

  @override
  List<Peer> get typingPeers => _matrixRoom.typingUsers
      .where((element) => element.id != client.user!.identifier)
      .map((e) => client.fetchPeer(e.id))
      .toList();

  @override
  String get developerInfo =>
      const JsonEncoder.withIndent('  ').convert(_matrixRoom.states);

  @override
  Color get defaultColor => isDirectMessage
      ? getColorOfUser(directMessagePartnerID!)
      : getColorOfUser(identifier);

  @override
  PushRule get pushRule {
    switch (_matrixRoom.pushRuleState) {
      case matrix.PushRuleState.notify:
        return PushRule.notify;
      case matrix.PushRuleState.mentionsOnly:
        return PushRule.notify;
      case matrix.PushRuleState.dontNotify:
        return PushRule.dontNotify;
    }
  }

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient)
      : super(room.id, client) {
    _matrixRoom = room;

    if (room.avatar != null) {
      avatar = MatrixMxcImage(room.avatar!, _matrixRoom.client,
          autoLoadFullRes: false);
    }

    isDirectMessage = _matrixRoom.isDirectChat;

    if (isDirectMessage) {
      directMessagePartnerID = _matrixRoom.directChatMatrixID!;
    }

    var memberStates = _matrixRoom.states["m.room.member"];
    if (memberStates?.length == 2 && !isDirectMessage) {
      //this might be a direct message room that hasnt been added to account data properly
      for (var key in memberStates!.keys) {
        var state = memberStates[key];
        if (state?.prevContent?["is_direct"] == true) {
          isDirectMessage = true;
          directMessagePartnerID = key;
        }
      }
    }

    displayName = room.getLocalizedDisplayname();

    // Note this is not necessarily all users, this has the most effect on smaller rooms
    // Where it is more likely that we are preloading important users
    var users = room.getParticipants();
    for (var user in users) {
      if (!this.client.peerExists(user.id)) {
        this.client.addPeer(MatrixPeer(client, matrixClient, user.id));
      }
    }

    timeline = MatrixTimeline(client, this, room);

    _matrixRoom.onUpdate.stream.listen(onMatrixRoomUpdate);

    roomEmoticons = MatrixRoomEmoticonComponent(
        MatrixRoomEmoticonHelper(_matrixRoom),
        this.client as MatrixClient,
        this);

    permissions = MatrixRoomPermissions(_matrixRoom);
  }

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) async {
    return await Future.wait(attachments.map((e) async {
      var file = await processAttachment(e);
      return MatrixProcessedAttachment(file!);
    }));
  }

  Future<matrix.MatrixFile?> processAttachment(
      PendingFileAttachment attachment) async {
    await attachment.resolve();
    if (attachment.data == null) return null;

    if (attachment.mimeType == "image/bmp") {
      var img = MemoryImage(attachment.data!);
      var image = await ImageUtils.imageProviderToImage(img);
      var bytes = await image.toByteData(format: ImageByteFormat.png);
      attachment.data = bytes!.buffer.asUint8List();
      attachment.mimeType = "image/png";
    }

    if (Mime.imageTypes.contains(attachment.mimeType)) {
      return await matrix.MatrixImageFile.create(
          bytes: attachment.data!,
          name: attachment.name ?? "unknown",
          mimeType: attachment.mimeType,
          nativeImplementations: (client as MatrixClient).nativeImplentations);
    }

    return matrix.MatrixFile(
        bytes: attachment.data!,
        name: attachment.name ?? "Unknown",
        mimeType: attachment.mimeType);
  }

  @override
  Future<TimelineEvent?> sendMessage(
      {String? message,
      TimelineEvent? inReplyTo,
      TimelineEvent? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) async {
    matrix.Event? replyingTo;

    if (inReplyTo != null) {
      replyingTo = await _matrixRoom.getEventById(inReplyTo.eventId);
    }

    if (processedAttachments != null) {
      Future.wait(processedAttachments
          .whereType<MatrixProcessedAttachment>()
          .map((e) => _matrixRoom.sendFileEvent(e.file)));
    }

    if (message != null && message.trim().isNotEmpty) {
      // String? id = await _matrixRoom.sendTextEvent(message,
      //     inReplyTo: replyingTo, editEventId: replaceEvent?.eventId);

      final event = <String, dynamic>{
        'msgtype': matrix.MessageTypes.Text,
        'body': message
      };

      final html = mx_markdown.markdown(message,
          getEmotePacks: () =>
              roomEmoticons.getEmotePacksFlat(matrix.ImagePackUsage.emoticon),
          getMention: _matrixRoom.getMention);

      if (HtmlUnescape().convert(html.replaceAll(RegExp(r'<br />\n?'), '\n')) !=
          event['body']) {
        event['format'] = 'org.matrix.custom.html';
        event['formatted_body'] = html;
      }

      var id = await _matrixRoom.sendEvent(event,
          inReplyTo: replyingTo, editEventId: replaceEvent?.eventId);

      if (id != null) {
        var event = await _matrixRoom.getEventById(id);
        return (timeline as MatrixTimeline).convertEvent(event!);
      }
    }

    return null;
  }

  @override
  Future<void> setDisplayNameInternal(String name) async {
    await _matrixRoom.setName(name);
  }

  @override
  Future<void> enableE2EE() async {
    await _matrixRoom.enableEncryption();
  }

  void onMatrixRoomUpdate(String event) async {
    displayName = _matrixRoom.getLocalizedDisplayname();
    onUpdate.add(null);
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    var newRule = _matrixRoom.pushRuleState;

    switch (rule) {
      case PushRule.notify:
        newRule = matrix.PushRuleState.notify;
        break;
      case PushRule.mentionsOnly:
        newRule = matrix.PushRuleState.mentionsOnly;
        break;
      case PushRule.dontNotify:
        newRule = matrix.PushRuleState.dontNotify;
        break;
    }

    await _matrixRoom.setPushRuleState(newRule);
    onUpdate.add(null);
  }

  @override
  Future<void> setTypingStatus(bool typing) async {
    await _matrixRoom.setTyping(typing, timeout: 2000);
  }

  @override
  Color getColorOfUser(String userId) {
    return MatrixPeer.hashColor(userId);
  }

  @override
  Future<TimelineEvent?> sendGif(
      GifSearchResult gif, TimelineEvent? inReplyTo) async {
    var response = await _matrixRoom.client.httpClient.get(gif.fullResUrl);
    if (response.statusCode == 200) {
      var data = response.bodyBytes;

      matrix.Event? replyingTo;
      var uri = await _matrixRoom.client
          .uploadContent(data, filename: "sticker", contentType: "image/gif");

      var content = {
        "body": "gif",
        "url": uri.toString(),
        "info": {
          "w": gif.x.toInt(),
          "h": gif.y.toInt(),
          "mimetype": "image/gif"
        }
      };

      if (inReplyTo != null) {
        replyingTo = await _matrixRoom.getEventById(inReplyTo.eventId);
      }

      var id = await _matrixRoom.sendEvent(content,
          type: matrix.EventTypes.Sticker, inReplyTo: replyingTo);

      if (id != null) {
        var event = await _matrixRoom.getEventById(id);
        return (timeline as MatrixTimeline).convertEvent(event!);
      }
    }
    throw UnimplementedError();
  }

  @override
  Future<TimelineEvent?> addReaction(
      TimelineEvent reactingTo, Emoticon reaction) async {
    var id = await _matrixRoom.sendReaction(reactingTo.eventId, reaction.key);
    if (id != null) {
      var event = await _matrixRoom.getEventById(id);
      return (timeline as MatrixTimeline).convertEvent(event!);
    }

    return null;
  }

  @override
  Future<void> removeReaction(
      TimelineEvent reactingTo, Emoticon reaction) async {
    return (timeline! as MatrixTimeline).removeReaction(reactingTo, reaction);
  }
}
