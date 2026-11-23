import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_activity.dart';
import 'package:flutter/material.dart';

class MatrixTimelineEventActivity extends MatrixTimelineEvent
    implements TimelineEventActivity {
  MatrixTimelineEventActivity(super.event, {required super.client});

  IconData get icon {
    return Icons.games_outlined;
  }

  @override
  String get plainTextBody => getBody();

  String getBody({Timeline? timeline}) {
    return event.body;
  }
}
