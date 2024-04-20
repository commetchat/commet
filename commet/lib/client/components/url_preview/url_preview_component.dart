import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:flutter/widgets.dart';

abstract class UrlPreviewComponent<T extends Client> implements Component<T> {
  bool shouldGetPreviewData(Room room, TimelineEvent event);

  Future<UrlPreviewData?> getPreview(Room room, TimelineEvent event);

  UrlPreviewData? getCachedPreview(Room room, TimelineEvent event);
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
