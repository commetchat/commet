import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixUrlPreviewComponent implements UrlPreviewComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixUrlPreviewComponent(this.client);

  Map<String, UrlPreviewData> cache = {};

  @override
  Future<UrlPreviewData?> getPreview(Room room, TimelineEvent event) async {
    if (room.isE2EE) {
      return null;
    }

    var mxClient = (room as MatrixRoom).matrixRoom.client;

    var uri = event.links!.first;
    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    } else {
      var data = await fetchPreviewData(mxClient, event.links!.first);
      cache[uri.toString()] = data!;
      return data;
    }
  }

  @override
  UrlPreviewData? getCachedPreview(Room room, TimelineEvent event) {
    var uri = event.links!.first;
    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    return null;
  }

  Future<UrlPreviewData?> fetchPreviewData(
      matrix.Client client, Uri url) async {
    var response = await client.request(
        matrix.RequestType.GET, "/media/v3/preview_url",
        query: {"url": url.toString()});

    var title = response['og:title'] as String?;
    var siteName = response['og:site_name'] as String?;
    var imageUrl = response['og:image'] as String?;
    var description = response['og:description'] as String?;
    ImageProvider? image;
    if (imageUrl != null) {
      var imageUri = Uri.parse(imageUrl);
      if (imageUri.scheme == "mxc") {
        image = MatrixMxcImage(imageUri, client);
      }
    }

    return UrlPreviewData(url,
        siteName: siteName,
        title: title,
        image: image,
        description: description);
  }
}
