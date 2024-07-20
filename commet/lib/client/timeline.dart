import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/material.dart';

enum TimelineEventStatus {
  error,
  sending,
  sent,
  synced,
  roomState,
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

  bool isEventRedacted(TimelineEvent event);
}
