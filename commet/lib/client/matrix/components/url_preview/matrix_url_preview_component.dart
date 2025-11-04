import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite.dart';

class MatrixUrlPreviewComponent implements UrlPreviewComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixUrlPreviewComponent(this.client);

  Map<String, UrlPreviewData> cache = {};

  bool? serverSupportsUrlPreview;

  @override
  Future<UrlPreviewData?> getPreview(
      Timeline timeline, TimelineEvent event) async {
    if (event is! TimelineEventMessage) {
      return null;
    }

    final room = timeline.room;

    if (room.isE2EE && preferences.urlPreviewInE2EEChat == false) {
      Log.i(
          "Not getting url preview because chat is encrypted and its not enabled");
      return null;
    }

    var mxClient = (room as MatrixRoom).matrixRoom.client;

    var uri = event.getLinks(timeline: timeline)!.first;

    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    UrlPreviewData? data;

    try {
      data = await fetchPreviewData(mxClient, uri);
    } catch (_) {
      return null;
    }

    if (data != null) {
      cache[uri.toString()] = data;
    }

    return data;
  }

  @override
  UrlPreviewData? getCachedPreview(Timeline timeline, TimelineEvent event) {
    if (event is! TimelineEventMessage) {
      return null;
    }

    var uri = event.getLinks(timeline: timeline)?.firstOrNull;

    if (uri == null) {
      return null;
    }

    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    return null;
  }

  @override
  bool shouldGetPreviewsInRoom(Room room) {
    if (room.isE2EE && preferences.urlPreviewInE2EEChat == false) {
      return false;
    }

    if (serverSupportsUrlPreview == false) {
      return false;
    }

    return true;
  }

  @override
  bool shouldGetPreviewDataForTimelineEvent(
      Timeline timeline, TimelineEvent event) {
    if (event is! TimelineEventMessage) {
      return false;
    }

    final room = timeline.room;

    if (!shouldGetPreviewsInRoom(room)) {
      return false;
    }

    final links = event.getLinks(timeline: timeline);

    return links?.isNotEmpty == true;
  }

  Future<String> getRequestPath() async {
    if (await client.getMatrixClient().authenticatedMediaSupported()) {
      return '/client/v1/media/preview_url';
    } else {
      return '/media/v3/preview_url';
    }
  }

  @override
  Future<UrlPreviewData?> getPreviewForUrl(Room room, Uri uri) async {
    if (shouldGetPreviewsInRoom(room) == false) {
      return null;
    }

    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    var data = null;

    try {
      data =
          await fetchPreviewData((room as MatrixRoom).matrixRoom.client, uri);
    } catch (_) {
      return null;
    }

    if (data != null) {
      cache[uri.toString()] = data;
    }

    return data;
  }

  Future<UrlPreviewData?> fetchPreviewData(
      matrix.Client client, Uri url) async {
    late Map<String, Object?> response;
    try {
      response = await client.request(
          matrix.RequestType.GET, await getRequestPath(),
          query: {"url": url.toString()});
    } catch (e, s) {
      if (e is MatrixException) {
        if (e.error == MatrixError.M_UNRECOGNIZED) {
          serverSupportsUrlPreview = false;
        }
      }

      Log.onError(e, s);

      return null;
    }

    serverSupportsUrlPreview = true;
    var title = response['og:title'] as String?;
    var siteName = response['og:site_name'] as String?;
    var imageUrl = response['og:image'] as String?;
    var description = response['og:description'] as String?;

    var type = response["og:image:type"] as String?;
    if (type != null) {
      if (Mime.displayableImageTypes.contains(type) == false) {
        imageUrl = null;
      }
    }

    ImageProvider? image;
    if (imageUrl != null) {
      var imageUri = Uri.parse(imageUrl);
      if (imageUri.scheme == "mxc") {
        try {
          image = MatrixMxcImage(imageUri, client, doThumbnail: false);
        } catch (exception, stack) {
          Log.onError(exception, stack);
          Log.w("Failed to get mxc image");
        }
      }
    }

    if (description != null) {
      description = description.replaceAll("\n", "    ");
    }

    return UrlPreviewData(url,
        siteName: siteName,
        title: title,
        image: image,
        description: description);
  }
}
