import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/components/video_embed/composite_video_provider.dart';
import 'package:commet/client/components/video_embed/video_embed_info.dart';
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

    if (room.isE2EE && preferences.urlPreviewInE2EEChat.value == false) {
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

    if (serverSupportsUrlPreview != false) {
      try {
        data = await fetchPreviewData(mxClient, uri);
      } catch (_) {
        data = null;
      }
    }

    data ??= await _fallbackVideoEmbed(uri);

    if (data != null) {
      cache[uri.toString()] = data;
    } else {
      cache[uri.toString()] = UrlPreviewComponent.invalidPreviewData;
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
    if (room.isE2EE && preferences.urlPreviewInE2EEChat.value == false) {
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

    final links = event.getLinks(timeline: timeline);
    if (links?.isNotEmpty != true) return false;

    if (!shouldGetPreviewsInRoom(room)) {
      // Allow fallback if client can directly handle the video link
      return links!.any(CompositeVideoProvider.instance.canHandle);
    }

    return true;
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
    if (uri.authority == "matrix.to") {
      return null;
    }

    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    UrlPreviewData? data;

    if (shouldGetPreviewsInRoom(room) != false &&
        serverSupportsUrlPreview != false) {
      try {
        data =
            await fetchPreviewData((room as MatrixRoom).matrixRoom.client, uri);
      } catch (_) {
        data = null;
      }
    }

    data ??= await _fallbackVideoEmbed(uri);

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

      return await _fallbackVideoEmbed(url);
    }

    serverSupportsUrlPreview = true;
    var title = response['og:title'] as String?;
    var siteName = response['og:site_name'] as String?;
    var imageUrl = response['og:image'] as String?;
    var description = response['og:description'] as String?;

    if (title == null && imageUrl == null) {
      final fallback = await _fallbackVideoEmbed(url);
      if (fallback != null) return fallback;
    }

    var video =
        (response['og:video:secure_url'] ?? response["og:video"]) as String?;
    var videoType = response['og:video:type'] as String?;

    int? videoWidth;
    int? videoHeight;

    var videoWidthStr = response['og:video:width'] as String?;
    var videoHeightStr = response['og:video:height'] as String?;

    if (videoHeightStr != null && videoWidthStr != null) {
      videoWidth = int.tryParse(videoWidthStr);
      videoHeight = int.tryParse(videoHeightStr);
    }

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

    var destinationType = UrlDestinationType.page;
    VideoAttachment? videoAttachment;
    VideoEmbedInfo? videoEmbedInfo;

    if (CompositeVideoProvider.instance.canHandle(url)) {
      destinationType = UrlDestinationType.video;
      try {
        videoEmbedInfo = await CompositeVideoProvider.instance.resolve(url);
        if (videoEmbedInfo != null) {
          siteName ??= videoEmbedInfo.platformName;
          title ??= videoEmbedInfo.title;
          image ??= videoEmbedInfo.thumbnail;
          if (videoEmbedInfo.streamUrl != null) {
            videoAttachment = VideoAttachment(
              WebFileProvider(videoEmbedInfo.streamUrl!),
              width: videoEmbedInfo.isShortForm ? 360 : 640,
              height: videoEmbedInfo.isShortForm ? 640 : 360,
              streamUrl: videoEmbedInfo.streamUrl,
              thumbnail: image ?? videoEmbedInfo.thumbnail,
              mimeType: 'video/mp4',
            );
          }
        }
      } catch (_) {}
    }

    if (video != null) {
      destinationType = UrlDestinationType.video;
    }

    if (videoAttachment == null &&
        video is String &&
        videoType != null &&
        (Mime.videoTypes.contains(videoType) ||
            Mime.videoStreamTypes.contains(videoType))) {
      var uri = Uri.parse(video);

      if (uri.scheme == "https") {
        videoAttachment = VideoAttachment(
          WebFileProvider(uri),
          width: videoWidth?.toDouble(),
          height: videoHeight?.toDouble(),
          streamUrl: uri,
          thumbnail: image,
          mimeType: videoType,
        );
      }
    }

    if (description != null) {
      description = description.replaceAll("\n", "    ");
    }

    return UrlPreviewData(
      url,
      siteName: siteName,
      title: title,
      image: image,
      video: videoAttachment,
      videoEmbedInfo: videoEmbedInfo,
      type: destinationType,
      description: description,
    );
  }

  Future<UrlPreviewData?> _fallbackVideoEmbed(Uri uri) async {
    if (!CompositeVideoProvider.instance.canHandle(uri)) return null;
    try {
      final videoInfo = await CompositeVideoProvider.instance.resolve(uri);
      if (videoInfo != null) {
        VideoAttachment? videoAttachment;
        if (videoInfo.streamUrl != null) {
          videoAttachment = VideoAttachment(
            WebFileProvider(videoInfo.streamUrl!),
            width: videoInfo.isShortForm ? 360 : 640,
            height: videoInfo.isShortForm ? 640 : 360,
            streamUrl: videoInfo.streamUrl,
            thumbnail: videoInfo.thumbnail,
            mimeType: 'video/mp4',
          );
        }

        return UrlPreviewData(
          uri,
          siteName: videoInfo.platformName,
          title: videoInfo.title,
          description: videoInfo.author != null
              ? 'by ${videoInfo.author}'
              : videoInfo.description,
          image: videoInfo.thumbnail,
          video: videoAttachment,
          type: UrlDestinationType.video,
          videoEmbedInfo: videoInfo,
        );
      }
    } catch (_) {}
    return null;
  }
}
