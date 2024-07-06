import 'dart:async';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:flutter/material.dart';

enum TimelineEventStatus {
  removed,
  error,
  sending,
  sent,
  synced,
  roomState,
}

enum EventType {
  unknown,
  message,
  sticker,
  emote,
  redaction,
  edit,
  invalid,
  encrypted,
  setRoomName,
  setRoomAvatar,
  roomCreated,
  memberJoined,
  memberLeft,
  memberAvatar,
  memberDisplayName,
  memberInvited,
  memberInvitationRejected,
  encryptionEnabled,
}

TimelineEventStatus eventStatusFromInt(int intValue) =>
    TimelineEventStatus.values[intValue + 2];

/// Takes two [EventStatus] values and returns the one with higher
/// (better in terms of message sending) status.
TimelineEventStatus latestEventStatus(
        TimelineEventStatus status1, TimelineEventStatus status2) =>
    status1.intValue > status2.intValue ? status1 : status2;

extension EventStatusExtension on TimelineEventStatus {
  /// Returns int value of the event status.
  ///
  /// - -2 == removed;
  /// - -1 == error;
  /// -  0 == sending;
  /// -  1 == sent;
  /// -  2 == synced;
  /// -  3 == roomState;
  int get intValue => (index - 2);

  /// Return `true` if the `EventStatus` equals `removed`.
  bool get isRemoved => this == TimelineEventStatus.removed;

  /// Return `true` if the `EventStatus` equals `error`.
  bool get isError => this == TimelineEventStatus.error;

  /// Return `true` if the `EventStatus` equals `sending`.
  bool get isSending => this == TimelineEventStatus.sending;

  /// Return `true` if the `EventStatus` equals `roomState`.
  bool get isRoomState => this == TimelineEventStatus.roomState;

  /// Returns `true` if the status is sent or later:
  /// [EventStatus.sent], [EventStatus.synced] or [EventStatus.roomState].
  bool get isSent => [
        TimelineEventStatus.sent,
        TimelineEventStatus.synced,
        TimelineEventStatus.roomState
      ].contains(this);

  /// Returns `true` if the status is `synced` or `roomState`:
  /// [EventStatus.synced] or [EventStatus.roomState].
  bool get isSynced => [
        TimelineEventStatus.synced,
        TimelineEventStatus.roomState,
      ].contains(this);
}

enum EventRelationshipType { reply }

abstract class TimelineEvent {
  String get eventId;
  EventType get type;
  bool get edited;
  bool get editable => type == EventType.message;
  TimelineEventStatus get status;
  String get senderId;
  DateTime get originServerTs;
  String? get body;
  String? get source;
  List<Attachment>? get attachments;
  String? get bodyFormat;
  String? get formattedBody;
  String get rawContent;
  List<Uri>? get links;

  /// This has a global key, and as such should only be displayed on screen in one place at a time.
  /// We cache it here so we dont have to parse formatting again on every rebuild
  /// If you want to display the same message twice, use `buildFormattedContent()` to create a new widget
  Widget? get formattedContent;

  Widget? buildFormattedContent();

  String? get relatedEventId;
  String? get stateKey;
  EventRelationshipType? get relationshipType;
  bool get highlight;

  Map<Emoticon, Set<String>>? get reactions;
}

abstract class Timeline {
  late List<TimelineEvent> events = List.empty(growable: true);
  final Map<String, TimelineEvent> _eventsDict = {};
  late StreamController<int> onEventAdded = StreamController.broadcast();
  late StreamController<int> onChange = StreamController.broadcast();
  late StreamController<int> onRemove = StreamController.broadcast();
  late Client client;
  late Room room;

  void markAsRead(TimelineEvent event);

  Future<void> loadMoreHistory();

  Future<void> close();

  @protected
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId);

  Future<TimelineEvent?> fetchEventById(String eventId) async {
    var event = await fetchEventByIdInternal(eventId);
    if (event == null) return null;
    _eventsDict[event.eventId] = event;
    return event;
  }

  void insertEvent(int index, TimelineEvent event) {
    events.insert(index, event);
    _eventsDict[event.eventId] = event;
    onEventAdded.add(index);
  }

  bool hasEvent(String eventId) {
    return _eventsDict.containsKey(eventId);
  }

  TimelineEvent? tryGetEvent(String eventId) {
    return _eventsDict[eventId];
  }

  void notifyChanged(int index) {
    onChange.add(index);
    _eventsDict[events[index].eventId] = events[index];
  }

  bool canDeleteEvent(TimelineEvent event);

  void deleteEvent(TimelineEvent event);
}
