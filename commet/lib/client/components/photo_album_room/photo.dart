import 'package:commet/client/attachment.dart';
import 'package:commet/client/timeline.dart';
import 'package:flutter/widgets.dart';

abstract class Photo {
  Attachment? get attachment;

  TimelineEventStatus get status;

  double? get width;
  double? get height;
}
