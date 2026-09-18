import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
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
  Future<GifSearchPage> search(String query, {String? pos}) async {
    // The ui should never actually let the user search if this is disabled, so this *shouldn't* be neccessary
    // but just to be safe!
    if (!preferences.tenorGifSearchEnabled.value) return GifSearchPage.empty;

    var page =
        await _request("search", {"q": query, if (pos != null) "pos": pos});
    // A proxy that rejects search is broken, not out of results
    if (page == null) throw Exception("Gif proxy rejected the search request");
    return page;
  }

  // COMMET: proxies that only allow search reject this, remember so we don't
  // ask again every time the picker opens
  String? _trendingUnsupportedProxy;

  @override
  Future<GifSearchPage> trending({String? pos}) async {
    if (!preferences.tenorGifSearchEnabled.value) return GifSearchPage.empty;
    if (_trendingUnsupportedProxy == preferences.proxyUrl.value) {
      return GifSearchPage.empty;
    }

    var page = await _request("featured", {if (pos != null) "pos": pos});
    // Only when the first page is rejected: a later page failing says
    // nothing about the endpoint
    if (page == null && pos == null) {
      _trendingUnsupportedProxy = preferences.proxyUrl.value;
    }

    return page ?? GifSearchPage.empty;
  }

  // Returns null if the proxy does not allow this endpoint
  Future<GifSearchPage?> _request(
      String endpoint, Map<String, String> params) async {
    var uri = Uri.https(
        preferences.proxyUrl.value, "/proxy/klipy/api/v2/$endpoint", params);

    var result = await http.get(uri);
    if (const [401, 403, 404].contains(result.statusCode)) {
      return null;
    }

    if (result.statusCode != 200) {
      throw Exception("Gif request failed (${result.statusCode})");
    }

    var data = jsonDecode(result.body) as Map<String, dynamic>;
    var results = data['results'] as List? ?? [];

    var parsed = <GifSearchResult>[];
    for (var e in results) {
      try {
        parsed.add(parseTenorResult(e as Map<String, dynamic>));
      } catch (_) {
        // skip results with missing formats rather than failing the page
      }
    }

    // A proxy that drops `pos` hands back the same cursor forever
    var next = data['next'];
    return GifSearchPage(parsed,
        next: next is String && next.isNotEmpty && next != params["pos"]
            ? next
            : null);
  }

  @override
  Stream<dynamic> get onFavoritesChanged => _changedController.stream;

  /// Where each gif we have sent lives on our homeserver, so sending it
  /// again skips the download and the upload, like a favorite does.
  final Map<Uri, Uri> _uploadedGifs = {};

  /// Set once the homeserver turns down reserving an mxc up front, so it
  /// isn't asked again for every gif.
  bool _asyncUploadUnsupported = false;

  /// Sends the message as soon as the gif has somewhere to live, and uploads
  /// it after. Uploading to the homeserver is the slow part, and it used to
  /// come first, so nothing showed in the chat for several seconds.
  @override
  Future<TimelineEvent?> sendGif(
      Room room, GifSearchResult gif, TimelineEvent? inReplyTo) async {
    var matrixRoom = (room as MatrixRoom).matrixRoom;
    final client = matrixRoom.client;

    final replyingTo = inReplyTo == null
        ? Future<matrix.Event?>.value(null)
        : matrixRoom.getEventById(inReplyTo.eventId);

    Future<void>? upload;
    var mxc = _uploadedGifs[gif.fullResUrl];
    if (mxc == null) {
      // Neither waits for the other.
      final reserving = _reserveMxc(client);
      final bytes = await _downloadGif(client, gif);
      final reserved = await reserving;

      if (reserved == null) {
        mxc = await client.uploadContent(bytes,
            filename: "sticker", contentType: gif.mimeType);
      } else {
        mxc = reserved;
        // Our own copy shows from the cache while it uploads.
        await _cacheLocally(reserved, bytes);
        upload = _uploadToReserved(client, reserved, bytes, gif.mimeType);
      }
    }

    var content = {
      "body": gif.fullResUrl.pathSegments.last,
      "url": mxc.toString(),
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

    var id = await matrixRoom.sendEvent(content,
        type: preferences.stickerCompatibilityMode.value
            ? matrix.EventTypes.Message
            : matrix.EventTypes.Sticker,
        inReplyTo: await replyingTo);

    if (id == null) throw Exception("Gif was not sent");

    if (upload != null) {
      try {
        await upload;
      } catch (_) {
        // The message points at media that never arrived: take it back
        // rather than leave everyone a broken image.
        await matrixRoom
            .redactEvent(id, reason: "The GIF failed to upload")
            .catchError((Object e, StackTrace s) {
          Log.onError(e, s, content: "Could not redact a gif that failed");
          return null;
        });
        rethrow;
      }
    }
    _uploadedGifs[gif.fullResUrl] = mxc;

    var event = await matrixRoom.getEventById(id);
    return room.convertEvent(event!,
        timeline: (room.timeline as MatrixTimeline).matrixTimeline);
  }

  Future<Uint8List> _downloadGif(
      matrix.Client client, GifSearchResult gif) async {
    var response = await client.httpClient.get(gif.fullResUrl);
    // Throw so the user is told, instead of it looking sent
    if (response.statusCode != 200) {
      throw Exception("Could not download gif (${response.statusCode})");
    }
    return response.bodyBytes;
  }

  /// An mxc to send the message with before the gif is uploaded to it
  /// (asynchronous uploads, `POST /_matrix/media/v1/create`), or null to
  /// upload first on a homeserver without them.
  Future<Uri?> _reserveMxc(matrix.Client client) async {
    if (_asyncUploadUnsupported) return null;
    try {
      return (await client.createContent()).contentUri;
    } on matrix.MatrixException catch (e) {
      if (e.error == matrix.MatrixError.M_UNRECOGNIZED ||
          e.error == matrix.MatrixError.M_NOT_FOUND) {
        _asyncUploadUnsupported = true;
      }
      Log.w("Could not reserve an mxc for a gif, uploading first: $e");
      return null;
    } catch (e) {
      Log.w("Could not reserve an mxc for a gif, uploading first: $e");
      return null;
    }
  }

  /// Retried: once the message is out, a failed upload means a broken image.
  Future<void> _uploadToReserved(
      matrix.Client client, Uri mxc, Uint8List bytes, String mimeType) async {
    for (var attempt = 1;; attempt++) {
      try {
        await client.uploadContentToMXC(mxc.host, mxc.pathSegments.first, bytes,
            filename: "sticker", contentType: mimeType);
        return;
      } on matrix.MatrixException catch (e) {
        // An earlier attempt landed after all.
        if (e.errcode == "M_CANNOT_OVERWRITE_MEDIA") return;
        if (attempt >= 3) rethrow;
        Log.w("Gif upload failed (attempt $attempt): $e");
      } catch (e) {
        if (attempt >= 3) rethrow;
        Log.w("Gif upload failed (attempt $attempt): $e");
      }
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }

  /// Puts the gif where our timeline looks for it first, so the message
  /// shows it at once instead of asking the homeserver for media that is
  /// still uploading.
  Future<void> _cacheLocally(Uri mxc, Uint8List bytes) async {
    try {
      await fileCache?.putFile(MatrixMxcImage.getIdentifier(mxc), bytes);
      await fileCache?.putFile(
          MatrixMxcImage.getThumbnailIdentifier(mxc), bytes);
    } catch (e, s) {
      Log.onError(e, s, content: "Could not cache a gif being sent");
    }
  }

  GifSearchResult parseTenorResult(Map<String, dynamic> result) {
    var formats = result['media_formats'] as Map<String, dynamic>;

    var preview =
        formats['tinygif'] ?? formats['nanogif'] ?? formats['mediumgif'];

    // The smallest of the full size versions: every byte of it is uploaded
    // to the homeserver on send, and a webp is often a tenth of the gif.
    var fullRes = formats['gif'];
    String mimeType = "image/gif";
    for (final (key, mime) in const [
      ('mediumgif', 'image/gif'),
      ('webp', 'image/webp'),
    ]) {
      final format = formats[key];
      if (format == null || format['size'] is! num || format['dims'] == null) {
        continue;
      }
      if (fullRes == null || format['size'] < fullRes['size']) {
        fullRes = format;
        mimeType = mime;
      }
    }

    var webp = formats["webp"];
    if (webp != null && webp['size'] < preview['size']) {
      preview = webp;
    }

    List<dynamic> dimensions = fullRes['dims']! as List<dynamic>;

    return GifSearchResult(
        convertUrl(preview['url']),
        convertUrl(fullRes['url']),
        (dimensions[0] as num).roundToDouble(),
        (dimensions[1] as num).roundToDouble(),
        mimeType,
        id: result['id']?.toString());
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

    // Throw so the picker can tell the user, like sendGif
    if (id == null) throw Exception("Gif was not sent");

    var event = await matrixRoom.getEventById(id);
    return room.convertEvent(event!,
        timeline: (room.timeline as MatrixTimeline).matrixTimeline);
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
