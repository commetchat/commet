import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/material.dart';

abstract class TimelineEventGeneric extends TimelineEventBase {
  String getBody({Timeline? timeline});

  IconData? get icon;

  bool get showSenderAvatar;
}
