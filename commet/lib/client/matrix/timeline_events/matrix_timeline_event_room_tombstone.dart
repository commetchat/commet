import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:commet/client/timeline_events/timeline_event_room_tombstone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatrixTimelineEventRoomTombstone extends MatrixTimelineEvent
    implements TimelineEventRoomTombstone, TimelineEventGeneric {
  MatrixTimelineEventRoomTombstone(super.event, {required super.client});

  String messageRoomUpgraded(String sender) => Intl.message(
        "$sender upgraded this room",
        name: "messageRoomUpgraded",
        args: [sender],
        desc: "Shown when a room was replaced by another room",
      );

  String get fallbackMessage => Intl.message(
        "This room has been upgraded or replaced",
        name: "messageRoomReplaced",
        desc: "Fallback tombstone text when no sender/body available",
      );

  @override
  String? get replacementRoomId => event.content["replacement_room"] as String?;

  @override
  String getBody({Timeline? timeline}) {
    final body = event.content["body"] as String?;
    if (body != null && body.trim().isNotEmpty) return body;

    final sender = timeline != null
        ? timeline.room.getMemberOrFallback(event.senderId).displayName
        : event.senderId.split(":").first.replaceFirst("@", "");

    if (sender != null && sender.isNotEmpty) {
      return messageRoomUpgraded(sender);
    }

    return fallbackMessage;
  }

  @override
  IconData? get icon => Icons.upgrade_rounded;

  @override
  bool get showSenderAvatar => false;
}
