import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventPowerLevels extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventPowerLevels(super.event, {required super.client});

  String messagePowerLevelsChanged(String user) =>
      Intl.message("$user changed the room power levels",
          desc: "Message to display when a user changes the room power levels",
          args: [user],
          name: "messagePowerLevelsChanged");

  @override
  String getBody({Timeline? timeline}) {
    String? sender = event.senderId.localpart;

    if (timeline != null) {
      sender = timeline.room.getMemberOrFallback(event.senderId).displayName;
    }

    if (sender != null) {
      return messagePowerLevelsChanged(sender);
    }

    return event.body;
  }

  @override
  String get plainTextBody => getBody();

  @override
  IconData? get icon => Icons.admin_panel_settings;

  @override
  bool get showSenderAvatar => false;
}
