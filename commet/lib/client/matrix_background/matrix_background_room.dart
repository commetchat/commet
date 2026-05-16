import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/client/matrix_background/matrix_background_events.dart';
import 'package:commet/client/matrix_background/matrix_background_member.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/role.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:drift/drift.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:flutter/src/widgets/icon_data.dart';
import 'package:matrix/encryption/utils/stored_inbound_group_session.dart'
    show StoredInboundGroupSession;
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'package:vodozemac/vodozemac.dart' as vod;

class MatrixBackgroundRoom implements Room {
  MatrixBackgroundClient backgroundClient;
  RoomDataData data;
  String roomId;
  List<PreloadRoomStateData> preloadState;
  List<NonPreloadRoomStateData> nonPreloadState;
  late List<matrix.BasicEvent> _stateEvents;

  MatrixBackgroundRoom(
    this.backgroundClient, {
    required this.roomId,
    required this.data,
    required this.preloadState,
    required this.nonPreloadState,
  }) {
    Log.d("Created background room with data: ${data.content}");

    _stateEvents = List.empty(growable: true);
    for (var preload in preloadState) {
      _stateEvents.add(matrix.BasicEvent.fromJson(jsonDecode(preload.content)));
    }

    for (var postLoad in nonPreloadState) {
      _stateEvents
          .add(matrix.BasicEvent.fromJson(jsonDecode(postLoad.content)));
    }
  }

  Future<void> init() async {
    var event = _stateEvents
        .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomName);

    if (event != null) {
      displayName = event.content["name"] as String;
    }

    var dms = client.getComponent<DirectMessagesComponent>();
    if (dms?.isRoomDirectMessage(this) == true) {
      var partnerId = dms?.getDirectMessagePartnerId(this);
      if (partnerId != null) {
        var partner = await fetchMember(partnerId);
        displayName = partner.displayName;
      }
    }

    if (displayName == "") {
      displayName = identifier;
    }

    if (avatarId != null) {
      avatar = await MatrixBackgroundMember.uriToCachedMxcImageProvider(
          Uri.parse(avatarId!));
    }
  }

  String? get avatarId => _stateEvents
      .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomAvatar)
      ?.content["url"] as String?;

  @override
  Future<TimelineEvent<Client>?> addReaction(
      TimelineEvent<Client> reactingTo, Emoticon reaction) {
    throw UnimplementedError();
  }

  @override
  ImageProvider<Object>? avatar;

  @override
  Future<void> cancelSend(TimelineEvent<Client> event) {
    throw UnimplementedError();
  }

  @override
  Client get client => backgroundClient;

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Color get defaultColor => getColorOfUser(identifier);

  @override
  String get developerInfo => throw UnimplementedError();

  @override
  int get displayHighlightedNotificationCount => throw UnimplementedError();

  @override
  String displayName = "";

  @override
  int get displayNotificationCount => throw UnimplementedError();

  @override
  Future<void> enableE2EE() {
    throw UnimplementedError();
  }

  @override
  Future<Member> fetchMember(String id) async {
    var db = backgroundClient.database.db;
    var data = await (db.select(db.roomMembers)
          ..where(
              (tbl) => tbl.roomId.equals(identifier) & tbl.userId.equals(id)))
        .getSingleOrNull();

    MatrixBackgroundMember result = MatrixBackgroundMember(id);
    if (data != null) {
      result = MatrixBackgroundMember(id, data: data);
    }

    await result.init();
    return result;
  }

  @override
  Future<List<Member>> fetchMembersList({bool cache = false}) {
    throw UnimplementedError();
  }

  @override
  List<T> getAllComponents<T extends RoomComponent<Client, Room>>() {
    throw UnimplementedError();
  }

  @override
  Color getColorOfUser(String userId) {
    return MatrixPeer.hashColor(userId);
  }

  @override
  T? getComponent<T extends RoomComponent<Client, Room>>() {
    throw UnimplementedError();
  }

  vod.InboundGroupSession? _createSession(String sessionKey) {
    try {
      return vod.InboundGroupSession(sessionKey);
    } catch (e, s) {
      Log.onError(e, s);
    }

    Log.i("Attempting import instead");
    try {
      return vod.InboundGroupSession.import(sessionKey);
    } catch (e, s) {
      Log.onError(e, s);
    }

    Log.i("Could not import key");

    return null;
  }

  Future<matrix.MatrixEvent?> attemptDecrypt(matrix.MatrixEvent result,
      String cipherText, StoredInboundGroupSession session) async {
    var key = jsonDecode(session.content);
    var sessionKey = key["session_key"];

    if (vod.isInitialized() == false) {
      await vod.init();
    }

    var sess = _createSession(sessionKey);

    if (sess != null) {
      try {
        var decrypted = sess.decrypt(cipherText);

        Log.i("Got decrypted: ${decrypted}");

        return matrix.MatrixEvent.fromJson({
          ...jsonDecode(decrypted.plaintext),
          "event_id": result.eventId,
          "room_id": result.roomId,
          "origin_server_ts": result.originServerTs.millisecondsSinceEpoch,
          "sender": result.senderId,
        });
      } catch (_) {
        Log.w("Decryption failed");
      }
    } else {
      Log.w("Failed to create session to decrypt event!");
    }
    return null;
  }

  Future<matrix.MatrixEvent> tryDecryptEvent(matrix.MatrixEvent result) async {
    Log.i("Attempting to decrypt incoming notification content");
    var ciphertext = result.content.tryGet<String>("ciphertext");
    var sessionId = result.content.tryGet<String>("session_id");
    var senderKey = result.content.tryGet<String>("sender_key");

    if (ciphertext == null) return result;

    StoredInboundGroupSession? session;

    if (senderKey != null) {
      var database = backgroundClient.database;

      var data = await (database.db.select(database.db.inboundGroupSession)
            ..where((tbl) =>
                tbl.roomId.equals(roomId) & tbl.senderKey.equals(senderKey)))
          .get();

      Log.i("Found ${data.length} sessions with matching sender_key");
      for (var entry in data) {
        Log.i("Got session via sender_key");
        session = StoredInboundGroupSession(
            roomId: entry.roomId,
            sessionId: entry.sessionId,
            pickle: entry.pickle,
            content: entry.content,
            indexes: entry.indexes,
            allowedAtIndex: entry.allowedAtIndex,
            senderKey: entry.senderKey,
            senderClaimedKeys: entry.senderClaimedKey);

        var decrypted = await attemptDecrypt(result, ciphertext, session);
        if (decrypted != null) {
          return decrypted;
        }
      }
    } else {
      session = await backgroundClient.database
          .getInboundGroupSession(result.roomId!, sessionId as String);

      if (session != null) {
        var decrypted = await attemptDecrypt(result, ciphertext, session);
        if (decrypted != null) {
          return decrypted;
        }
      }
    }

    return result;
  }

  @override
  Future<TimelineEvent<Client>?> getEvent(String eventId) async {
    var result =
        await backgroundClient.api.getOneRoomEvent(identifier, eventId);
    Log.i("Received event: ${result}");

    if (result.type == matrix.EventTypes.Encrypted) {
      result = await tryDecryptEvent(result);
    }

    if ([
      matrix.EventTypes.Encrypted,
      matrix.EventTypes.Message,
    ].contains(result.type)) {
      return MatrixBackgroundTimelineEventMessage(result);
    }

    return null;
  }

  @override
  Member getMemberOrFallback(String id) {
    throw UnimplementedError();
  }

  @override
  Role getMemberRole(String identifier) {
    throw UnimplementedError();
  }

  @override
  Future<ImageProvider<Object>?> getShortcutImage() async {
    return null;
  }

  @override
  Future<Timeline> getTimeline({String? contextEventId}) {
    throw UnimplementedError();
  }

  @override
  int get highlightedNotificationCount => throw UnimplementedError();

  @override
  IconData get icon => throw UnimplementedError();

  @override
  String get identifier => roomId;

  @override
  List<(Member, Role)> importantMembers() {
    throw UnimplementedError();
  }

  @override
  bool get isE2EE =>
      _stateEvents.any((e) => e.type == matrix.EventTypes.Encryption);

  @override
  bool get isMembersListComplete => throw UnimplementedError();

  @override
  Key get key => throw UnimplementedError();

  @override
  TimelineEvent<Client>? get lastEvent => throw UnimplementedError();

  @override
  TimelineEvent? get lastMessage => throw UnimplementedError();

  @override
  DateTime get lastEventTimestamp => throw UnimplementedError();

  @override
  String get localId => throw UnimplementedError();

  @override
  Iterable<String> get memberIds => throw UnimplementedError();

  @override
  List<Member> membersList() {
    throw UnimplementedError();
  }

  @override
  int get notificationCount => throw UnimplementedError();

  @override
  Stream<void> get onUpdate => throw UnimplementedError();

  @override
  Permissions get permissions => throw UnimplementedError();

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) {
    throw UnimplementedError();
  }

  PushRule get pushRule => throw UnimplementedError();

  @override
  Future<void> removeReaction(
      TimelineEvent<Client> reactingTo, Emoticon reaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> retrySend(TimelineEvent<Client> event) {
    throw UnimplementedError();
  }

  @override
  Future<TimelineEvent<Client>?> sendMessage(
      {String? message,
      TimelineEvent<Client>? inReplyTo,
      TimelineEvent<Client>? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDisplayName(String newName) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPushRule(PushRule rule) {
    throw UnimplementedError();
  }

  @override
  bool shouldNotify(TimelineEvent<Client> event) {
    throw UnimplementedError();
  }

  @override
  bool get shouldPreviewMedia => throw UnimplementedError();

  @override
  Timeline? get timeline => throw UnimplementedError();

  @override
  Member? getMember(String id) {
    // TODO: implement getMember
    throw UnimplementedError();
  }

  @override
  // TODO: implement isSpecialRoomType
  bool get isSpecialRoomType => false;

  @override
  Future<void> banUser(String id) {
    // TODO: implement banUser
    throw UnimplementedError();
  }

  @override
  Future<void> kickUser(String id) {
    // TODO: implement kickUser
    throw UnimplementedError();
  }

  @override
  // TODO: implement availableRoles
  List<Role> get availableRoles => throw UnimplementedError();

  @override
  Future<void> setMemberRole(String id, Role role) {
    // TODO: implement setMemberRole
    throw UnimplementedError();
  }

  @override
  // TODO: implement topic
  String? get topic => throw UnimplementedError();

  @override
  Future<void> setTopic(String topic) {
    // TODO: implement setTopic
    throw UnimplementedError();
  }

  @override
  Future<void> setRoomAvatar(Uint8List bytes, String? mimeType) {
    // TODO: implement setRoomAvatar
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead() {
    // TODO: implement markAsRead
    throw UnimplementedError();
  }

  @override
  // TODO: implement visibility
  RoomVisibility get visibility => throw UnimplementedError();

  @override
  Future<void> setVisibility(RoomVisibility visibility) {
    // TODO: implement setVisibility
    throw UnimplementedError();
  }

  @override
  // TODO: implement isFavorite
  bool get isFavorite => false;

  @override
  Future<void> setAsFavorite(bool favorite) {
    // TODO: implement setAsFavorite
    throw UnimplementedError();
  }
}
