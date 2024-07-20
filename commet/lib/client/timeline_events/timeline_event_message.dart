import 'package:commet/client/attachment.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/material.dart';

abstract class TimelineEventMessage extends TimelineEventBase {
  Widget? buildFormattedContent({Timeline? timeline});
  String? get body;

  List<Attachment>? get attachments;

  bool isEdited(Timeline timeline);

  List<Uri>? get links => null;
}
