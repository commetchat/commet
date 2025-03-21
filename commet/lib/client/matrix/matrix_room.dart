import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_attachment.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_role.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_add_reaction.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_edit.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_emote.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_encrypted.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_membership.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_message.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_pinned_messages.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_redaction.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_sticker.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_unknown.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/role.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:matrix/matrix_api_lite/model/stripped_state_event.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart' as mx_markdown;

import '../attachment.dart';
import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

@Reflector()
class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  late String _displayName;

  late MatrixRoomPermissions _permissions;

  final StreamController<void> _onUpdate = StreamController.broadcast();

  final StreamController<void> onTimelineLoaded = StreamController.broadcast();

  late final List<RoomComponent<MatrixClient, MatrixRoom>> _components;

  ImageProvider? _avatar;

  late MatrixClient _client;

  MatrixTimeline? _timeline;

  matrix.Room get matrixRoom => _matrixRoom;

  @override
  String get displayName => _displayName;

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
  DateTime get lastEventTimestamp => lastEvent == null
      ? _lastStateEventTimestamp
      : lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  TimelineEvent? lastEvent;

  @override
  Iterable<String> get memberIds =>
      _matrixRoom.getParticipants([matrix.Membership.join]).map((e) => e.id);

  @override
  String get developerInfo =>
      const JsonEncoder.withIndent('  ').convert(_matrixRoom.states);

  @override
  Color get defaultColor => getColorOfUser(identifier);

  @override
  PushRule get pushRule {
    switch (_matrixRoom.pushRuleState) {
      case matrix.PushRuleState.notify:
        return PushRule.notify;
      case matrix.PushRuleState.mentionsOnly:
        return PushRule.mentionsOnly;
      case matrix.PushRuleState.dontNotify:
        return PushRule.dontNotify;
    }
  }

  @override
  ImageProvider<Object>? get avatar {
    final comp = client.getComponent<DirectMessagesComponent>();

    if (comp == null) {
      return _avatar;
    }

    if (comp.isRoomDirectMessage(this)) {
      final partner = comp.getDirectMessagePartnerId(this);
      if (partner != null) {
        return getMemberOrFallback(partner).avatar;
      }
    }

    return _avatar;
  }

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
    matrix.Event? latest = room.lastEvent;

    if (latest != null) {
      lastEvent = convertEvent(latest);
    }

    updateAvatar();

    _onUpdateSubscription = _matrixRoom.client.onRoomState.stream
        .where((event) => event.roomId == _matrixRoom.id)
        .listen(onRoomStateUpdated);

    _matrixRoom.client.onEvent.stream
        .where((event) => event.roomID == _matrixRoom.id)
        .listen(onEvent);

    _permissions = MatrixRoomPermissions(_matrixRoom);
  }

  Future<void> updateAvatar() async {
    if (_matrixRoom.avatar != null) {
      _avatar = MatrixMxcImage(_matrixRoom.avatar!, _matrixRoom.client,
          autoLoadFullRes: false);
    } else if (_matrixRoom.isDirectChat) {
      var url = await _matrixRoom.client
          .getAvatarUrl(_matrixRoom.directChatMatrixID!);
      if (url != null) {
        _avatar = MatrixMxcImage(url, _matrixRoom.client);
      }
    }

    _onUpdate.add(null);
  }

  void onEvent(matrix.EventUpdate eventUpdate) async {
    if (eventUpdate.roomID != identifier) {
      return;
    }

    if (eventUpdate.content["type"] == matrix.EventTypes.Message) {
      var roomEvent =
          await matrixRoom.getEventById(eventUpdate.content['event_id']);
      if (roomEvent == null) {
        return;
      }

      var event = convertEvent(roomEvent);
      if (lastEvent == null) {
        lastEvent = event;
        _onUpdate.add(null);
      } else if (event.originServerTs.isAfter(lastEvent!.originServerTs)) {
        lastEvent = event;
        _onUpdate.add(null);
      }
      handleNotification(event);
    }
  }

  Future<void> handleNotification(TimelineEvent event) async {
    if (!shouldNotify(event)) {
      return;
    }

    // let push notifications handle it
    if (BuildConfig.ANDROID) {
      return;
    }

    var sender = await fetchMember(event.senderId);

    bool isDirectMessage = client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(this) ??
        false;

    if (event is TimelineEventMessage) {
      var notification = MessageNotificationContent(
          senderName: sender.displayName,
          senderId: sender.identifier,
          roomName: displayName,
          senderImage: sender.avatar,
          roomImage: avatar,
          content: event.body ?? "Received a message",
          eventId: event.eventId,
          roomId: identifier,
          clientId: client.identifier,
          isDirectMessage: isDirectMessage);

      NotificationManager.notify(notification);
    }
  }

  @override
  bool shouldNotify(TimelineEvent event) {
    // never notify for a message that came from an account we are logged in to!
    if (clientManager?.clients
            .any((element) => element.self?.identifier == event.senderId) ==
        true) {
      return false;
    }

    var timeDiff = DateTime.now().difference(event.originServerTs);

    // dont notify if we are receiving an old message
    if (timeDiff.inMinutes > 10) {
      return false;
    }

    var evaluator = _matrixRoom.client.pushruleEvaluator;
    var match = evaluator.match((event as MatrixTimelineEvent).event);

    return match.notify;
  }

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) async {
    return await Future.wait(attachments.map((e) async {
      return (await processAttachment(e))!;
    }));
  }

  Future<MatrixProcessedAttachment?> processAttachment(
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

    try {
      if (Mime.imageTypes.contains(attachment.mimeType)) {
        await decodeImageFromList(attachment.data!);
        return MatrixProcessedAttachment(await matrix.MatrixImageFile.create(
            bytes: attachment.data!,
            name: attachment.name ?? "unknown",
            mimeType: attachment.mimeType,
            nativeImplementations:
                (client as MatrixClient).nativeImplentations));
      }
    } catch (error, stack) {
      // This image is probably corrupt, since it has a mime type we should be able to display,
      // But we can't decode the image. Just clear the mime type so clients dont try to display this bad file
      attachment.mimeType = 'application/octet-stream';
      Log.onError(error, stack);
    }

    matrix.MatrixImageFile? thumbnailImageFile;
    if (attachment.thumbnailFile != null) {
      var decodedImage = await decodeImageFromList(attachment.thumbnailFile!);

      thumbnailImageFile = matrix.MatrixImageFile(
          bytes: attachment.thumbnailFile!,
          width: decodedImage.width,
          height: decodedImage.height,
          mimeType: attachment.thumbnailMime,
          name: "thumbnail");
    }

    if (Mime.videoTypes.contains(attachment.mimeType)) {
      return MatrixProcessedAttachment(
        matrix.MatrixVideoFile(
          bytes: attachment.data!,
          name: attachment.name ?? "Unknown",
          mimeType: attachment.mimeType,
          width: attachment.dimensions?.width.toInt(),
          height: attachment.dimensions?.height.toInt(),
          duration: attachment.length?.inMilliseconds,
        ),
        thumbnailFile: thumbnailImageFile,
      );
    }

    return MatrixProcessedAttachment(
        matrix.MatrixFile(
            bytes: attachment.data!,
            name: attachment.name ?? "Unknown",
            mimeType: attachment.mimeType),
        thumbnailFile: thumbnailImageFile);
  }

  @override
  Future<TimelineEvent?> sendMessage(
      {String? message,
      TimelineEvent? inReplyTo,
      TimelineEvent? replaceEvent,
      String? threadRootEventId,
      String? threadLastEventId,
      List<ProcessedAttachment>? processedAttachments}) async {
    matrix.Event? replyingTo;

    if (inReplyTo != null) {
      replyingTo = await _matrixRoom.getEventById(inReplyTo.eventId);
    }

    if (processedAttachments != null) {
      Future.wait(
          processedAttachments.whereType<MatrixProcessedAttachment>().map((e) {
        return _matrixRoom.sendFileEvent(e.file,
            threadLastEventId: threadLastEventId,
            threadRootEventId: threadRootEventId,
            thumbnail: e.thumbnailFile);
      }));
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
          inReplyTo: replyingTo,
          editEventId: replaceEvent?.eventId,
          threadLastEventId: threadLastEventId,
          threadRootEventId: threadRootEventId);

      if (id != null) {
        var event = await _matrixRoom.getEventById(id);
        return convertEvent(event!);
      }
    }

    return null;
  }

  TimelineEvent convertEvent(matrix.Event event, {matrix.Timeline? timeline}) {
    var c = client as MatrixClient;
    try {
      if (event.redacted) {
        return MatrixTimelineEventUnknown(event, client: c);
      }

      if (event.type == matrix.EventTypes.Message) {
        if (event.relationshipType == "m.replace")
          return MatrixTimelineEventEdit(event, client: c);
        if (event.content["chat.commet.type"] == "chat.commet.sticker" &&
            event.content['url'] is String)
          return MatrixTimelineEventSticker(event, client: c);

        if (event.messageType == "m.emote")
          return MatrixTimelineEventEmote(event, client: c);

        return MatrixTimelineEventMessage(event, client: c);
      }

      final result = switch (event.type) {
        matrix.EventTypes.Sticker =>
          event.content['url'] is String || event.content.containsKey('file')
              ? MatrixTimelineEventSticker(event, client: c)
              : null,
        matrix.EventTypes.Encrypted =>
          MatrixTimelineEventEncrypted(event, client: c),
        matrix.EventTypes.Reaction =>
          MatrixTimelineEventAddReaction(event, client: c),
        matrix.EventTypes.RoomMember =>
          MatrixTimelineEventMembership(event, client: c),
        matrix.EventTypes.Redaction =>
          MatrixTimelineEventRedaction(event, client: c),
        matrix.EventTypes.RoomPinnedEvents =>
          MatrixTimelineEventPinnedMessages(event, client: c),
        _ => null
      };

      if (result != null) {
        return result;
      } else {
        return MatrixTimelineEventUnknown(event, client: c);
      }
    } catch (err, trace) {
      Log.e("Failed to parse event ${event.eventId} in room ${event.roomId}");
      Log.onError(err, trace, content: "Failed to parse event: ${event.type}");
      return MatrixTimelineEventUnknown(event, client: c);
    }
  }

  @override
  Future<void> enableE2EE() async {
    await _matrixRoom.enableEncryption();
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
  Color getColorOfUser(String userId) {
    return MatrixPeer.hashColor(userId);
  }

  @override
  Future<TimelineEvent?> addReaction(
      TimelineEvent reactingTo, Emoticon reaction) async {
    var id = await _matrixRoom.sendReaction(reactingTo.eventId, reaction.key);
    if (id != null) {
      var event = await _matrixRoom.getEventById(id);
      return convertEvent(event!);
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
  List<T> getAllComponents<T extends RoomComponent<Client, Room>>() {
    return List.from(_components);
  }

  @override
  Future<void> close() async {
    await _onUpdate.close();
    await _onUpdateSubscription?.cancel();
    await timeline?.close();
  }

  @override
  Future<Timeline> getTimeline({String? contextEventId}) async {
    _timeline = MatrixTimeline(client as MatrixClient, this, matrixRoom);
    await _timeline!.initTimeline(contextEventId: contextEventId);
    onTimelineLoaded.add(null);
    return _timeline!;
  }

  @override
  Future<ImageProvider?> getShortcutImage() async {
    if (avatar != null) return avatar;

    final comp = client.getComponent<DirectMessagesComponent>();

    if (comp?.isRoomDirectMessage(this) == true) {
      var user =
          await client.getProfile(comp!.getDirectMessagePartnerId(this)!);

      if (user?.avatar != null) {
        return user!.avatar;
      }
    }

    return client.spaces
        .where((space) => space.containsRoom(identifier))
        .firstOrNull
        ?.avatar;
  }

  @override
  Future<TimelineEvent?> getEvent(String eventId) async {
    var event = await _matrixRoom.getEventById(eventId);
    if (event == null) {
      return null;
    }

    if (event.type == matrix.EventTypes.Encrypted) {
      try {
        await event.requestKey();
      } catch (_) {
        Log.i("Failed to decrypt event: $event");
      }
    }

    return convertEvent(event);
  }

  @override
  List<Member> membersList() {
    var users = _matrixRoom.getParticipants();
    return users.map((e) => MatrixMember(_matrixRoom.client, e)).toList();
  }

  @override
  Future<List<Member>> fetchMembersList({bool cache = false}) async {
    var results = await _matrixRoom
        .requestParticipants([matrix.Membership.join], true, cache);

    return results.map((e) => MatrixMember(_matrixRoom.client, e)).toList();
  }

  @override
  bool get isMembersListComplete => _matrixRoom.participantListComplete;

  @override
  Member getMemberOrFallback(String id) {
    return MatrixMember(
        _matrixRoom.client, _matrixRoom.unsafeGetUserFromMemoryOrFallback(id));
  }

  @override
  Future<Member> fetchMember(String id) async {
    var member = await _matrixRoom.requestUser(id);
    if (member != null) {
      return MatrixMember(_matrixRoom.client, member);
    } else {
      return getMemberOrFallback(id);
    }
  }

  @override
  List<(Member, Role)> importantMembers() {
    var state = _matrixRoom.states["m.room.power_levels"]?[""];
    if (state == null) return [];

    var roles = (state.content["users"] as Map<String, dynamic>);
    var ids = roles.keys;

    var result =
        ids.map((e) => (getMemberOrFallback(e), MatrixRole(roles[e]))).toList();

    result.removeWhere((element) => element.$2.rank == 0);

    result.sort((a, b) => b.$2.rank.compareTo(a.$2.rank));

    return result;
  }

  @override
  Role getMemberRole(String identifier) {
    return MatrixRole(_matrixRoom.getPowerLevelByUserId(identifier));
  }

  void onRoomStateUpdated(({String roomId, StrippedStateEvent state}) event) {
    _displayName = _matrixRoom.getLocalizedDisplayname();
    if (event.state.type == "m.room.name") {
      _onUpdate.add(null);
    }
  }

  @override
  Future<void> cancelSend(TimelineEvent event) async {
    final mxEvent = event as MatrixTimelineEvent;
    await mxEvent.event.cancelSend();
  }

  @override
  Future<void> retrySend(TimelineEvent event) async {
    final mxEvent = event as MatrixTimelineEvent;
    await mxEvent.event.sendAgain();
  }
}
