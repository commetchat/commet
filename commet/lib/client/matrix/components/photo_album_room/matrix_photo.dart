import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:flutter/src/painting/image_provider.dart';

class MatrixPhoto implements Photo {
  final MatrixTimelineEvent event;

  @override
  final Attachment attachment;

  MatrixPhoto(
    this.event, {
    required this.attachment,
  });

  @override
  double get height {
    if (attachment is ImageAttachment) {
      return (attachment! as ImageAttachment).height!;
    }

    if (attachment is VideoAttachment) {
      return (attachment! as VideoAttachment).height!;
    }

    throw UnimplementedError();
  }

  @override
  double get width {
    if (attachment is ImageAttachment) {
      return (attachment! as ImageAttachment).width!;
    }

    if (attachment is VideoAttachment) {
      return (attachment! as VideoAttachment).width!;
    }

    throw UnimplementedError();
  }

  @override
  ImageProvider<Object> get image {
    if (attachment is ImageAttachment) {
      return (attachment! as ImageAttachment).image!;
    }

    if (attachment is VideoAttachment) {
      return (attachment! as VideoAttachment).thumbnail!;
    }

    throw UnimplementedError();
  }
}
