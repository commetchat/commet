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

  // This is a dummy value that we can store in the cache when we fail to get the url preview.
  // Instead of storing null, which is a bit confusing as if the cache returns null, does that mean we have
  // nothing cached, or the result was invalid? maybe this is dumb but it was the simplest way
  // to prevent weird ui glitches when failed fetches kept getting retried.
  static UrlPreviewData invalidPreviewData =
      UrlPreviewData(Uri.new(), title: "Unable to get url preview ");
}

class UrlPreviewData {
  final Uri uri;
  final String? siteName;
  final String? title;
  final String? description;
  final ImageProvider? image;

  const UrlPreviewData(
    this.uri, {
    this.siteName,
    this.title,
    this.description,
    this.image,
  });
}
