import 'dart:async';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/peer.dart';
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
  message,
  redaction,
  edit,
  invalid;
}

TimelineEventStatus eventStatusFromInt(int intValue) => TimelineEventStatus.values[intValue + 2];

/// Takes two [EventStatus] values and returns the one with higher
/// (better in terms of message sending) status.
TimelineEventStatus latestEventStatus(TimelineEventStatus status1, TimelineEventStatus status2) =>
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
  bool get isSent =>
      [TimelineEventStatus.sent, TimelineEventStatus.synced, TimelineEventStatus.roomState].contains(this);

  /// Returns `true` if the status is `synced` or `roomState`:
  /// [EventStatus.synced] or [EventStatus.roomState].
  bool get isSynced => [
        TimelineEventStatus.synced,
        TimelineEventStatus.roomState,
      ].contains(this);
}

class TimelineEvent {
  String eventId = "";
  EventType type = EventType.invalid;
  late TimelineEventStatus status;
  late Peer sender;
  late DateTime originServerTs;
  // todo: make this better
  late String? body;
  late Widget? widget;
  List<Attachment>? attachments;
}

abstract class Timeline {
  late List<TimelineEvent> events = List.empty(growable: true);
  late StreamController<int> onEventAdded = StreamController.broadcast();
  late Client client;

  Future<void> loadMoreHistory();

  void insertEvent(int index, TimelineEvent event) {
    events.insert(index, event);
    onEventAdded.add(index);
  }
}
