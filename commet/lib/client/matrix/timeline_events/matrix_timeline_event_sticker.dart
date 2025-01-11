import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_mixin_reactions.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_mixin_related.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:flutter/material.dart';

class MatrixTimelineEventSticker extends MatrixTimelineEvent
    with MatrixTimelineEventRelated, MatrixTimelineEventReactions
    implements TimelineEventSticker {
  MatrixTimelineEventSticker(super.event, {required super.client}) {
    String? uri;
    if (event.content.containsKey('url')) {
      uri = event.content['url'] as String;
    } else if (event.content.containsKey('file')) {
      var file = event.content['file'] as Map<String, dynamic>;
      uri = file['url'];
    }
    stickerImage = MatrixMxcImage(Uri.parse(uri!), client.getMatrixClient(),
        matrixEvent: event);

    stickerName = event.body;
  }

  @override
  late ImageProvider<Object> stickerImage;

  @override
  late String stickerName;

  @override
  String get plainTextBody => stickerName;
}
