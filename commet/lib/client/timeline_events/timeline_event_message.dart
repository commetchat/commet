import 'package:commet/client/attachment.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/material.dart';

abstract class TimelineEventMessage extends TimelineEvent {
  Widget? buildFormattedContent({Timeline? timeline});
  String? get body;
  String? get bodyFormat;
  String? get formattedBody;

  List<Attachment>? get attachments;

  bool isEdited(Timeline timeline);

  List<Uri>? getLinks({Timeline? timeline});
}
