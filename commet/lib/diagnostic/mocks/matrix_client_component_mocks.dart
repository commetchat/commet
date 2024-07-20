import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:flutter/material.dart';

extension MatrixClientComponentReplacement on MatrixClient {
  void mockComponents() {
    componentsInternal.removeWhere((element) => element is UrlPreviewComponent);
    componentsInternal.add(MockMatrixUrlPreviewComponent(this));
  }
}

class MockMatrixUrlPreviewComponent
    implements UrlPreviewComponent<MatrixClient> {
  @override
  MatrixClient client;

  MockMatrixUrlPreviewComponent(this.client);

  var imageIndex = 0;

  @override
  Future<UrlPreviewData?> getPreview(Room room, TimelineEvent? event) async {
    await Future.delayed(const Duration(seconds: 1));

    var image = [
      "assets/images/app_icon/app_icon_filled.png",
      "assets/images/app_icon/app_icon_rounded.png",
      "assets/images/app_icon/app_icon_transparent_cropped.png",
      "assets/images/app_icon/app_icon_transparent.png"
    ][imageIndex % 4];

    imageIndex += 1;

    return UrlPreviewData(Uri.parse("https://example.com"),
        siteName: "Example",
        description: "Example description",
        image: AssetImage(image));
  }

  @override
  bool shouldGetPreviewData(Room room, TimelineEvent event) {
    return true;
  }

  @override
  UrlPreviewData? getCachedPreview(Room room, TimelineEvent event) {
    return null;
  }
}
