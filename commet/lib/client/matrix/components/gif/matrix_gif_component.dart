import 'dart:async';
import 'dart:convert';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:http/http.dart' as http;

import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/config/style/theme_json_converter.dart';

class MatrixFavoriteGif implements FavoriteGif {
  Map<String, dynamic> data;
  MatrixClient client;

  MatrixFavoriteGif(this.client, this.data);

  @override
  double get height {
    var info = data.tryGetMap("info");
    return info?.tryGetDouble("h") ?? 512;
  }

  @override
  ImageProvider<Object> get image {
    var url = data.tryGet<String>("url");
    return MatrixMxcImage(Uri.parse(url!), client.matrixClient);
  }

  @override
  double get width {
    var info = data.tryGetMap("info");
    return info?.tryGetDouble("w") ?? 512;
  }

  @override
  String get url => data.tryGet<String>("url")!;
}

class MatrixGifComponent implements GifComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixGifComponent(this.client) {
    client.matrixClient.onSync.stream.listen(_onSync);
  }

  @override
  String get searchPlaceholder => "Search KLIPY";

  static const String favoritesKey = "chat.commet.favorite_stickers";

  StreamController _changedController = StreamController.broadcast();

  @override
  Future<List<GifSearchResult>> search(String query) async {
    // The ui should never actually let the user search if this is disabled, so this *shouldn't* be neccessary
    // but just to be safe!
    if (!preferences.tenorGifSearchEnabled.value) return [];

    var uri = Uri.https(
        preferences.proxyUrl.value, "/proxy/klipy/api/v2/search", {"q": query});

    // var uri =
    //     Uri.http("localhost:8788", "/proxy/klipy/api/v2/search", {"q": query});

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
  Stream<dynamic> get onFavoritesChanged => _changedController.stream;

  @override
  Future<TimelineEvent?> sendGif(
      Room room, GifSearchResult gif, TimelineEvent? inReplyTo) async {
    var matrixRoom = (room as MatrixRoom).matrixRoom;
    var response = await matrixRoom.client.httpClient.get(gif.fullResUrl);
    if (response.statusCode == 200) {
      var data = response.bodyBytes;

      matrix.Event? replyingTo;
      var uri = await matrixRoom.client
          .uploadContent(data, filename: "sticker", contentType: gif.mimeType);

      var content = {
        "body": gif.fullResUrl.pathSegments.last,
        "url": uri.toString(),
        if (preferences.stickerCompatibilityMode.value) "msgtype": "m.image",
        if (preferences.stickerCompatibilityMode.value)
          "chat.commet.type": "chat.commet.sticker",
        "info": {
          "chat.commet.animated": true,
          "w": gif.x.toInt(),
          "h": gif.y.toInt(),
          "mimetype": gif.mimeType
        }
      };

      if (inReplyTo != null) {
        replyingTo = await matrixRoom.getEventById(inReplyTo.eventId);
      }

      var id = await matrixRoom.sendEvent(content,
          type: preferences.stickerCompatibilityMode.value
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

    String mimeType = "image/gif";

    var preview =
        formats['tinygif'] ?? formats['nanogif'] ?? formats['mediumgif'];

    var fullRes = formats['gif'];

    //We only want to send full res if less than 3mb
    if (fullRes['size'] as int > sizeLimit && formats['mediumgif'] != null) {
      fullRes = formats['mediumgif'];
    }

    if (formats["webp"]['size'] < fullRes['size']) {
      fullRes = formats["webp"];
      mimeType = "image/webp";
    }

    if (formats["webp"]['size'] < preview['size']) {
      preview = formats["webp"];
    }

    List<dynamic> dimensions = fullRes['dims']! as List<dynamic>;

    return GifSearchResult(
        convertUrl(preview['url']),
        convertUrl(fullRes['url']),
        (dimensions[0] as int).roundToDouble(),
        (dimensions[1] as int).roundToDouble(),
        mimeType);
  }

  Uri convertUrl(String url) {
    var uri = Uri.parse(url);

    var proxyUri =
        Uri.https(preferences.proxyUrl.value, "/proxy/klipy/media${uri.path}");

    // proxyUri = Uri.http("localhost:8788", "/proxy/klipy/media${uri.path}");

    return proxyUri;
  }

  @override
  bool isGif(TimelineEvent<Client> ev) {
    final event = (ev as MatrixTimelineEvent).event;

    bool isSticker = event.type == "m.sticker" ||
        (event.type == "m.room.message" &&
            event.content["chat.commet.type"] == "chat.commet.sticker");

    bool isGifMimeType = Mime.gifTypes.contains(event.attachmentMimetype);

    var info = event.content.tryGetMap("info");

    bool isAnimated = event.attachmentMimetype == "image/gif" ||
        info?["chat.commet.animated"] == true;

    bool isGif = isSticker && isGifMimeType && isAnimated;

    return isGif;
  }

  @override
  Future<void> setFavoriteFromEvent(TimelineEvent<Client> ev) async {
    final event = (ev as MatrixTimelineEvent).event;
    var info = event.content.tryGetMap("info");
    var body = event.content.tryGet<String>("body");
    var url = event.content.tryGet<String>("url");

    var favorites = client.matrixClient.accountData[favoritesKey]?.content
            .tryGetList<Map<String, dynamic>>("favorites") ??
        List<Map<String, dynamic>>.empty();

    if (favorites.any((i) => i["url"] == url)) {
      return;
    }

    final newFavorites = List.from(favorites, growable: true);
    newFavorites.add({
      "info": info,
      "body": body,
      "url": url,
    });

    print(newFavorites);

    await client.matrixClient.setAccountData(
        client.matrixClient.userID!, favoritesKey, {"favorites": newFavorites});
  }

  @override
  bool isFavoriteGif(TimelineEvent<Client> ev) {
    var favorites = client.matrixClient.accountData[favoritesKey]?.content
            .tryGetList<Map<String, dynamic>>("favorites") ??
        List<Map<String, dynamic>>.empty();

    final event = (ev as MatrixTimelineEvent).event;

    if (favorites.any((i) => i["url"] == event.content["url"])) {
      return true;
    }

    return false;
  }

  @override
  List<FavoriteGif> get favorites {
    var favorites = client.matrixClient.accountData[favoritesKey]?.content
        .tryGetList<Map<String, dynamic>>("favorites");

    if (favorites == null) return [];

    return favorites.map((i) => MatrixFavoriteGif(client, i)).toList();
  }

  @override
  Future<TimelineEvent<Client>?> sendFavoriteGif(
      Room room, FavoriteGif gif, TimelineEvent<Client>? inReplyTo) async {
    var fav = gif as MatrixFavoriteGif;
    matrix.Event? replyingTo;
    var matrixRoom = (room as MatrixRoom).matrixRoom;

    var content = {
      "body": fav.data["body"],
      "url": fav.data["url"],
      if (preferences.stickerCompatibilityMode.value) "msgtype": "m.image",
      if (preferences.stickerCompatibilityMode.value)
        "chat.commet.type": "chat.commet.sticker",
      "info": fav.data["info"]
    };

    if (inReplyTo != null) {
      replyingTo = await matrixRoom.getEventById(inReplyTo.eventId);
    }

    var id = await matrixRoom.sendEvent(content,
        type: preferences.stickerCompatibilityMode.value
            ? matrix.EventTypes.Message
            : matrix.EventTypes.Sticker,
        inReplyTo: replyingTo);

    if (id != null) {
      var event = await matrixRoom.getEventById(id);
      return room.convertEvent(event!,
          timeline: (room.timeline as MatrixTimeline).matrixTimeline);
    }

    return null;
  }

  @override
  Future<void> removeFavoriteFromEvent(TimelineEvent<Client> ev) async {
    final event = (ev as MatrixTimelineEvent).event;
    var url = event.content.tryGet<String>("url");

    var favorites = client.matrixClient.accountData[favoritesKey]?.content
            .tryGetList<Map<String, dynamic>>("favorites") ??
        List<Map<String, dynamic>>.empty();

    var newFavorites =
        List<Map<String, dynamic>>.from(favorites, growable: true);

    newFavorites.removeWhere((i) => i["url"] == url);

    await client.matrixClient.setAccountData(
        client.matrixClient.userID!, favoritesKey, {"favorites": newFavorites});
  }

  void _onSync(matrix.SyncUpdate event) {
    if (event.accountData?.any((i) => i.type == favoritesKey) == true) {
      _changedController.add(null);
    }
  }

  @override
  Future<void> removeFavorite(FavoriteGif gif) async {
    var favorites = client.matrixClient.accountData[favoritesKey]?.content
            .tryGetList<Map<String, dynamic>>("favorites") ??
        List<Map<String, dynamic>>.empty();

    var newFavorites =
        List<Map<String, dynamic>>.from(favorites, growable: true);

    newFavorites.removeWhere((i) => i["url"] == gif.url);

    await client.matrixClient.setAccountData(
        client.matrixClient.userID!, favoritesKey, {"favorites": newFavorites});
  }
}
