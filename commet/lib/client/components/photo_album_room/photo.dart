import 'package:commet/client/attachment.dart';
import 'package:commet/client/timeline.dart';

abstract class Photo {
  Attachment? get attachment;

  TimelineEventStatus get status;

  String get id;

  double? get width;
  double? get height;
}
