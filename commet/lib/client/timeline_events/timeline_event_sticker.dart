import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/material.dart';

abstract class TimelineEventSticker extends TimelineEvent {
  String get stickerName;

  ImageProvider get stickerImage;
}
