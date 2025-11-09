import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/widgets.dart';

abstract class UrlPreviewComponent<T extends Client> implements Component<T> {
  bool shouldGetPreviewDataForTimelineEvent(
      Timeline timeline, TimelineEvent event);

  bool shouldGetPreviewsInRoom(Room room);

  Future<UrlPreviewData?> getPreview(Timeline timeline, TimelineEvent event);

  Future<UrlPreviewData?> getPreviewForUrl(Room room, Uri url);

  UrlPreviewData? getCachedPreview(Timeline timeline, TimelineEvent event);
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
