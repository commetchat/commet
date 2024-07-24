import 'dart:convert';

import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/main.dart';
import 'package:http/http.dart' as http;

import 'package:matrix/matrix.dart' as matrix;

class MatrixGifComponent implements GifComponent<MatrixClient, MatrixRoom> {
  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  MatrixGifComponent(this.client, this.room);

  @override
  String get searchPlaceholder => "Search Tenor";

  @override
  Future<List<GifSearchResult>> search(String query) async {
    // The ui should never actually let the user search if this is disabled, so this *shouldn't* be neccessary
    // but just to be safe!
    if (!preferences.tenorGifSearchEnabled) return [];

    var uri = Uri.https(
        preferences.proxyUrl, "/proxy/tenor/api/v2/search", {"q": query});

    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var data = jsonDecode(result.body) as Map<String, dynamic>;
      var results = data['results'] as List?;

      if (results != null) {
        return results.map((e) => parseTenorResult(e)).toList();
      }
    }

    return [];
  }

  @override
  Future<TimelineEvent?> sendGif(
      GifSearchResult gif, TimelineEvent? inReplyTo) async {
    var matrixRoom = room.matrixRoom;
    var response = await matrixRoom.client.httpClient.get(gif.fullResUrl);
    if (response.statusCode == 200) {
      var data = response.bodyBytes;

      matrix.Event? replyingTo;
      var uri = await matrixRoom.client
          .uploadContent(data, filename: "sticker", contentType: "image/gif");

      var content = {
        "body": gif.fullResUrl.pathSegments.last,
        "url": uri.toString(),
        if (preferences.stickerCompatibilityMode) "msgtype": "m.image",
        if (preferences.stickerCompatibilityMode)
          "chat.commet.type": "chat.commet.sticker",
        "info": {
          "w": gif.x.toInt(),
          "h": gif.y.toInt(),
          "mimetype": "image/gif"
        }
      };

      if (inReplyTo != null) {
        replyingTo = await matrixRoom.getEventById(inReplyTo.eventId);
      }

      var id = await matrixRoom.sendEvent(content,
          type: preferences.stickerCompatibilityMode
              ? matrix.EventTypes.Message
              : matrix.EventTypes.Sticker,
          inReplyTo: replyingTo);

      if (id != null) {
        var event = await matrixRoom.getEventById(id);
        return room.convertEvent(event!,
            timeline: (room.timeline as MatrixTimeline).matrixTimeline);
      }
    }

    return null;
  }

  GifSearchResult parseTenorResult(Map<String, dynamic> result) {
    const int sizeLimit = 3000000; //3 MB

    var formats = result['media_formats'] as Map<String, dynamic>;

    var preview =
        formats['tinygif'] ?? formats['nanogif'] ?? formats['mediumgif'];

    //dynamic fullRes;

    var fullRes = formats['gif'];

    //We only want to send full res if less than 3mb
    if (fullRes['size'] as int > sizeLimit && formats['mediumgif'] != null) {
      fullRes = formats['mediumgif'];
    }

    List<dynamic> dimensions = fullRes['dims']! as List<dynamic>;

    return GifSearchResult(
        convertUrl(preview['url']),
        convertUrl(fullRes['url']),
        (dimensions[0] as int).roundToDouble(),
        (dimensions[1] as int).roundToDouble());
  }

  Uri convertUrl(String url) {
    var uri = Uri.parse(url);

    var proxyUri =
        Uri.https(preferences.proxyUrl, "/proxy/tenor/media${uri.path}");

    return proxyUri;
  }
}
