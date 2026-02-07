import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatrixTimelineEventEditCalendar extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventEditCalendar(super.event, {required super.client});

  String messagePlaceholderUserEditedCalendar(String user) =>
      Intl.message("$user edited the calendar",
          desc: "Message body for when a user edits the room calendar",
          args: [user],
          name: "messagePlaceholderUserEditedCalendar");

  @override
  IconData get icon {
    return Icons.calendar_month;
  }

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  @override
  String getBody({Timeline? timeline}) {
    var name = event.senderFromMemoryOrFallback.displayName ?? event.senderId;

    return messagePlaceholderUserEditedCalendar(name);
  }
}
