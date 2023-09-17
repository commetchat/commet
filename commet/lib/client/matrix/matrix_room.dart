import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_attachment.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/permissions.dart';
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

  late String _displayName;

  late bool _isDirectMessage;

  late String? _directPartnerId;

  late MatrixRoomPermissions _permissions;

  final StreamController<void> _onUpdate = StreamController.broadcast();

  late final List<RoomComponent<MatrixClient, MatrixRoom>> _components;

  ImageProvider? _avatar;

  late MatrixClient _client;

  late MatrixTimeline _timeline;

  matrix.Room get matrixRoom => _matrixRoom;

  @override
  String? get directMessagePartnerID => _directPartnerId;

  @override
  String get displayName => _displayName;

  @override
  bool get isDirectMessage => _isDirectMessage;

  @override
  Stream<void> get onUpdate => _onUpdate.stream;

  @override
  Permissions get permissions => _permissions;

  @override
  bool get isE2EE => _matrixRoom.encrypted;

  @override
  int get highlightedNotificationCount => _matrixRoom.highlightCount;

  @override
  int get notificationCount => _matrixRoom.notificationCount;

  late DateTime _lastStateEventTimestamp;
  @override
  DateTime get lastEventTimestamp =>
      lastEvent == null ? _lastStateEventTimestamp : lastEvent!.originServerTs;

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
      .where((element) => element.id != client.self!.identifier)
      .map((e) => client.getPeer(e.id))
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

  @override
  ImageProvider<Object>? get avatar => _avatar;

  @override
  Client get client => _client;

  @override
  String get identifier => _matrixRoom.id;

  @override
  Timeline? get timeline => _timeline;

  StreamSubscription? _onUpdateSubscription;

  MatrixRoom(
      MatrixClient client, matrix.Room room, matrix.Client matrixClient) {
    _matrixRoom = room;
    _client = client;

    _displayName = room.getLocalizedDisplayname();
    _components = ComponentRegistry.getMatrixRoomComponents(client, this);

    if (room.avatar != null) {
      _avatar = MatrixMxcImage(room.avatar!, _matrixRoom.client,
          autoLoadFullRes: false);
    }

    _lastStateEventTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

    for (var e in room.states.values) {
      for (var event in e.values) {
        if (event.originServerTs.isAfter(_lastStateEventTimestamp)) {
          _lastStateEventTimestamp = event.originServerTs;
        }
      }
    }

    _isDirectMessage = _matrixRoom.isDirectChat;

    if (isDirectMessage) {
      _directPartnerId = _matrixRoom.directChatMatrixID!;
    }

    var memberStates = _matrixRoom.states["m.room.member"];
    if (memberStates?.length == 2 && !isDirectMessage) {
      //this might be a direct message room that hasnt been added to account data properly
      for (var key in memberStates!.keys) {
        var state = memberStates[key];
        if (state?.prevContent?["is_direct"] == true) {
          _isDirectMessage = true;
          _directPartnerId = key;
        }
      }
    }

    // Note this is not necessarily all users, this has the most effect on smaller rooms
    // Where it is more likely that we are preloading important users
    var users = room.getParticipants();
    for (var user in users) {
      this.client.getPeer(user.id);
    }

    _timeline = MatrixTimeline(client, this, room);

    _onUpdateSubscription =
        _matrixRoom.onUpdate.stream.listen(onMatrixRoomUpdate);

    _permissions = MatrixRoomPermissions(_matrixRoom);
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
      final event = <String, dynamic>{
        'msgtype': matrix.MessageTypes.Text,
        'body': message
      };

      var emoticons = getComponent<MatrixRoomEmoticonComponent>();
      final html = mx_markdown.markdown(message,
          getEmotePacks: emoticons != null
              ? () =>
                  emoticons.getEmotePacksFlat(matrix.ImagePackUsage.emoticon)
              : null,
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
  Future<void> enableE2EE() async {
    await _matrixRoom.enableEncryption();
  }

  void onMatrixRoomUpdate(String event) async {
    _displayName = _matrixRoom.getLocalizedDisplayname();
    _onUpdate.add(null);
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
    _onUpdate.add(null);
  }

  @override
  Future<void> setDisplayName(String newName) async {
    _displayName = newName;
    _onUpdate.add(null);
    await _matrixRoom.setName(newName);
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

  @override
  T? getComponent<T extends RoomComponent>() {
    for (var component in _components) {
      if (component is T) return component as T;
    }

    return null;
  }

  @override
  Future<void> close() async {
    await _onUpdate.close();
    await _onUpdateSubscription?.cancel();
    await timeline?.close();
  }
}
