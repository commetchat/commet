import 'dart:async';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';

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
  redaction,
  edit,
  invalid,
  setRoomName,
  setRoomAvatar,
  roomCreated,
  memberJoined,
  memberLeft,
  memberAvatar,
  memberDisplayName,
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

class TimelineEvent {
  String eventId = "";
  EventType type = EventType.invalid;
  bool edited = false;
  late TimelineEventStatus status;
  late String senderId;
  late DateTime originServerTs;
  String? body;
  late String? source = "";
  List<Attachment>? attachments;
  String? bodyFormat;
  String? formattedBody;
  Widget? formattedContent;
  String? relatedEventId;
  EventRelationshipType? relationshipType;

  late StreamController onChange = StreamController.broadcast();
}

abstract class Timeline {
  late List<TimelineEvent> events = List.empty(growable: true);
  final Map<String, TimelineEvent> _eventsDict = {};
  late StreamController<int> onEventAdded = StreamController.broadcast();
  late StreamController<int> onChange = StreamController.broadcast();
  late StreamController<int> onRemove = StreamController.broadcast();
  late Client client;
  late Room room;

  Iterable<String>? get receipts;

  void markAsRead(TimelineEvent event);

  Future<void> loadMoreHistory();

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

  void insertNewEvent(int index, TimelineEvent event) {
    if (shouldDisplayNotification(event)) displayNotification(event);

    insertEvent(index, event);
  }

  bool hasEvent(String eventId) {
    return _eventsDict.containsKey(eventId);
  }

  TimelineEvent? tryGetEvent(String eventId) {
    return _eventsDict[eventId];
  }

  @protected
  bool shouldDisplayNotification(TimelineEvent event) {
    if (event.type != EventType.message) return false;

    if (event.senderId == client.user!.identifier) return false;

    if (room.pushRule == PushRule.dontNotify) return false;

    var containingSpaces = room.client.spaces
        .where((element) => element.containsRoom(room.identifier))
        .toList();

    if (containingSpaces
        .every((space) => space.pushRule == PushRule.dontNotify)) {
      return false;
    }

    return true;
  }

  @protected
  void displayNotification(TimelineEvent event) {
    notificationManager.notify(NotificationContent(
        room.client.fetchPeer(event.senderId).displayName,
        event.body ?? T.current.notificationReceivedMessagePlaceholder,
        NotificationType.messageReceived,
        sentFrom: room,
        image: room.client.fetchPeer(event.senderId).avatar,
        event: event));
  }

  void notifyChanged(int index) {
    onChange.add(index);
    events[index].onChange.add(null);
  }

  void deleteEvent(String eventId) {
    throw UnimplementedError();
  }

  void deleteEventByIndex(int index) {
    throw UnimplementedError();
  }
}
