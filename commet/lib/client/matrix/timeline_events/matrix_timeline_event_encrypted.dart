import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';

class MatrixTimelineEventEncrypted extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventEncrypted(super.event, {required super.client});

  @override
  String getBody({Timeline? timeline}) {
    return "Failed to decrypt event";
  }

  @override
  IconData? get icon => null;

  @override
  bool get showSenderAvatar => true;
}
