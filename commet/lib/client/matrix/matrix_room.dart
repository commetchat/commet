import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:commet/client/matrix/extensions/matrix_room_extensions.dart';
import 'package:commet/client/matrix/matrix_attachment.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_emoticon.dart';
import 'package:commet/client/matrix/matrix_emoticon_pack.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart' as mx_markdown;

import '../attachment.dart';
import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  @override
  bool get isMember => _matrixRoom.membership == matrix.Membership.join;

  @override
  bool get isE2EE => _matrixRoom.encrypted;

  @override
  int get highlightedNotificationCount => _matrixRoom.highlightCount;

  @override
  int get notificationCount => _matrixRoom.notificationCount;

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

  List<EmoticonPack> _roomEmojis = List.empty(growable: true);

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

  @override
  List<EmoticonPack> get availbleEmoji =>
      _getAvailablePacks(includeUnicode: true);

  @override
  List<EmoticonPack> get ownedEmoji => _roomEmojis;

  List<EmoticonPack> _getAvailablePacks({bool includeUnicode = false}) {
    var result = List<EmoticonPack>.of(ownedEmoji);

    for (var space
        in client.spaces.where((element) => element.containsRoom(identifier))) {
      result.addAll(space.ownedEmoji);
    }
    if (includeUnicode) result.addAll(UnicodeEmojis.packs!);

    return result;
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

    displayName = room.getLocalizedDisplayname();

    // Note this is not necessarily all users, this has the most effect on smaller rooms
    // Where it is more likely that we are preloading important users
    var users = room.getParticipants();
    for (var user in users) {
      if (!this.client.peerExists(user.id)) {
        this.client.addPeer(MatrixPeer(matrixClient, user.id));
      }
    }

    timeline = MatrixTimeline(client, this, room);

    _matrixRoom.onUpdate.stream.listen(onMatrixRoomUpdate);
    _roomEmojis = MatrixEmoticonPack.getPacks(_matrixRoom);
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
              getEmotePacksFlat(matrix.ImagePackUsage.emoticon),
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
  Future<void> createEmoticonPack(String name, Uint8List? avatarData) async {
    var data = await _matrixRoom.createEmoticonPack(name, avatarData);
    if (data != null) {
      var pack = MatrixEmoticonPack(data['key'], _matrixRoom, data['content']);
      _roomEmojis.add(pack);
      onEmojiPackAdded.add(_roomEmojis.length - 1);
    }
  }

  @override
  Future<void> deleteEmoticonPack(EmoticonPack pack) async {
    await _matrixRoom.deleteEmoticonPack(pack.identifier);
    _roomEmojis.remove(pack);
  }

  Map<String, Map<String, String>> getEmotePacksFlat(
      matrix.ImagePackUsage emoticon) {
    var packs = _getAvailablePacks(includeUnicode: false)
        .whereType<MatrixEmoticonPack>();

    var result = <String, Map<String, String>>{};

    for (var pack in packs) {
      var key = "${pack.displayName}-${pack.ownedRoomId}";
      result[key] = <String, String>{};
      for (var emote in pack.emotes) {
        result[key]![emote.shortcode!] =
            (emote as MatrixEmoticon).emojiUrl.toString();
      }
    }

    return result;
  }
}
