import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/material.dart';

abstract class TimelineEventSticker extends TimelineEventBase {
  String get stickerName;

  ImageProvider get stickerImage;
}
