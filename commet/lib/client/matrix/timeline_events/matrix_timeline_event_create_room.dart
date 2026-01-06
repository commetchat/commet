import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatrixTimelineEventCreateRoom extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventCreateRoom(super.event, {required super.client});

  String messagePlaceholderUserCreatedRoom(String user) =>
      Intl.message("$user created the room!",
          desc: "Message body for when a user creates the room",
          args: [user],
          name: "messagePlaceholderUserCreatedRoom");

  @override
  IconData get icon {
    return Icons.add;
  }

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  @override
  String getBody({Timeline? timeline}) {
    var name = event.senderFromMemoryOrFallback.displayName ?? event.senderId;

    return messagePlaceholderUserCreatedRoom(name);
  }
}
