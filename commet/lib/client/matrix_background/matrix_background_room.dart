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
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix/matrix.dart' as matrix;

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

  @override
  Future<TimelineEvent<Client>?> getEvent(String eventId) async {
    var result =
        await backgroundClient.api.getOneRoomEvent(identifier, eventId);
    Log.i("Received event: ${result}");

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
}
