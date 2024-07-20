import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/widgets.dart';

abstract class UrlPreviewComponent<T extends Client> implements Component<T> {
  bool shouldGetPreviewData(Room room, TimelineEventBase event);

  Future<UrlPreviewData?> getPreview(Room room, TimelineEventBase event);

  UrlPreviewData? getCachedPreview(Room room, TimelineEventBase event);
}

class UrlPreviewData {
  Uri uri;
  String? siteName;
  String? title;
  String? description;
  ImageProvider? image;

  UrlPreviewData(
    this.uri, {
    this.siteName,
    this.title,
    this.description,
    this.image,
  });
}
