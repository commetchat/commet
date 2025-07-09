import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/matrix/extensions/matrix_event_extensions.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_message.dart';
import 'package:commet/client/timeline.dart';
import 'package:flutter/src/painting/image_provider.dart';

class MatrixPhoto implements Photo {
  final MatrixTimelineEvent event;

  Attachment? get attachment =>
      (event as MatrixTimelineEventMessage).attachments?.firstOrNull;

  MatrixPhoto(
    this.event,
  );

  @override
  double? get height =>
      (event as MatrixTimelineEventMessage).event.attachmentHeight;

  @override
  double? get width =>
      (event as MatrixTimelineEventMessage).event.attachmentWidth;

  @override
  TimelineEventStatus get status => event.status;
}
