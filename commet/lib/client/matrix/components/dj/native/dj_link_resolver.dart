// Turns a pasted link into queue entries on the DJ's desktop client.
//
// YouTube and SoundCloud (and anything else yt-dlp knows) are listed with
// yt-dlp. Spotify's audio is DRM protected, so a Spotify link is read for
// its songs' titles and artists (from the public embed page, no API key) and
// each song is played from YouTube, found by a search when it is its turn.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/matrix/components/dj/native/dj_tools.dart';
import 'package:commet/client/matrix/components/dj/native/yt_dlp.dart';
import 'package:http/http.dart' as http;

class NativeDjLinkResolver implements DjResolver {
  final http.Client _http;

  NativeDjLinkResolver({http.Client? client}) : _http = client ?? http.Client();

  static final Random _random = Random();
  static String _newId() =>
      List.generate(3, (_) => _random.nextInt(1 << 30).toRadixString(36))
          .join();

  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) async {
    // Spotify's short share links (from the phone app) redirect to the
    // real page, which is what can be read.
    final host = Uri.tryParse(link.url)?.host ?? '';
    if (link.type == DjLinkType.other &&
        (host == 'spotify.link' || host.endsWith('.app.link'))) {
      final target = await _followRedirects(Uri.parse(link.url));
      final real = target == null ? null : DjLinks.parse(target.toString());
      if (real == null || real.type == DjLinkType.other) {
        throw StateError("That Spotify link doesn't lead to a song");
      }
      return resolve(real, addedBy: addedBy);
    }
    switch (link.type) {
      case DjLinkType.spotifyTrack:
      case DjLinkType.spotifyAlbum:
      case DjLinkType.spotifyPlaylist:
        return SpotifyEmbed(_http).tracks(link, addedBy: addedBy);
      default:
        final tools = await DjTools.instance.locate();
        if (tools == null) {
          throw StateError('The DJ tools are not set up');
        }
        final json =
            await YtDlp(tools).inspect(link.url, playlist: link.isCollection);
        final tracks = tracksFromYtDlp(json, link, addedBy: addedBy);
        if (tracks.isEmpty) throw StateError('Nothing playable in that link');
        return tracks;
    }
  }

  Future<Uri?> _followRedirects(Uri url) async {
    var current = url;
    for (var hop = 0; hop < 5; hop++) {
      final request = http.Request('GET', current)..followRedirects = false;
      final response =
          await _http.send(request).timeout(const Duration(seconds: 15));
      await response.stream.drain<void>();
      final location = response.headers['location'];
      if (response.statusCode < 300 ||
          response.statusCode >= 400 ||
          location == null) {
        return current;
      }
      current = current.resolve(location);
      if (current.host == 'open.spotify.com') return current;
    }
    return null;
  }

  /// Queue entries from yt-dlp's `--dump-single-json --flat-playlist`.
  static List<DjTrack> tracksFromYtDlp(Map<String, Object?> json, DjLink link,
      {required String addedBy, String Function()? newId}) {
    newId ??= _newId;
    final entries = json['_type'] == 'playlist' && json['entries'] is List
        ? (json['entries'] as List).whereType<Map<String, Object?>>()
        : [json];
    final tracks = <DjTrack>[];
    for (final entry in entries) {
      final url = _string(entry['webpage_url']) ??
          _string(entry['original_url']) ??
          _string(entry['url']);
      if (url == null) continue;
      final kind = _kindOf(entry, link);
      final id = _string(entry['id']);
      final youtubeId = kind == DjSource.youtube && id != null && id.length == 11
          ? id
          : DjLinks.youtubeVideoId(url);
      tracks.add(DjTrack(
        id: newId(),
        source: youtubeId != null
            ? 'https://www.youtube.com/watch?v=$youtubeId'
            : url,
        kind: kind,
        title: _string(entry['track']) ??
            _string(entry['title']) ??
            _titleFromUrl(url),
        artist: _artistOf(entry),
        durationMs: _durationMs(entry['duration']),
        thumbnail: youtubeId != null
            ? DjLinks.youtubeThumbnail(youtubeId)
            : _thumbnailOf(entry),
        addedBy: addedBy,
      ));
    }
    return tracks;
  }

  static DjSource _kindOf(Map<String, Object?> entry, DjLink link) {
    final extractor = (_string(entry['ie_key']) ??
            _string(entry['extractor_key']) ??
            '')
        .toLowerCase();
    if (extractor.startsWith('youtube')) return DjSource.youtube;
    if (extractor.startsWith('soundcloud')) return DjSource.soundcloud;
    return link.source == DjSource.spotify ? DjSource.other : link.source;
  }

  static String? _artistOf(Map<String, Object?> entry) {
    final artists = entry['artists'];
    if (artists is List && artists.isNotEmpty) {
      return artists.whereType<String>().join(', ');
    }
    final name = _string(entry['artist']) ??
        _string(entry['creator']) ??
        _string(entry['uploader']) ??
        _string(entry['channel']);
    // YouTube's auto-generated music channels: "Artist - Topic".
    return name?.replaceFirst(RegExp(r'\s+-\s+Topic$'), '');
  }

  static String? _thumbnailOf(Map<String, Object?> entry) {
    final single = _string(entry['thumbnail']);
    if (single != null) return single;
    final thumbnails = entry['thumbnails'];
    if (thumbnails is List && thumbnails.isNotEmpty) {
      final last = thumbnails.last;
      if (last is Map) return _string(last['url']);
    }
    return null;
  }

  /// "https://soundcloud.com/artist/some-track-name" -> "Some track name".
  static String _titleFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty);
    final slug = segments == null || segments.isEmpty ? url : segments.last;
    final words = slug.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    if (words.isEmpty) return url;
    return words[0].toUpperCase() + words.substring(1);
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static int? _durationMs(Object? seconds) =>
      seconds is num && seconds > 0 ? (seconds * 1000).round() : null;
}

/// Spotify's public embed pages, which carry a track's title, artists and
/// length, or the first 50 or so tracks of an album or playlist.
class SpotifyEmbed {
  final http.Client _http;

  SpotifyEmbed(this._http);

  static final Random _random = Random();

  Future<List<DjTrack>> tracks(DjLink link,
      {required String addedBy, String Function()? newId}) async {
    newId ??= () => List.generate(
        3, (_) => _random.nextInt(1 << 30).toRadixString(36)).join();
    final type = link.url.split('/').reversed.skip(1).first;
    final response = await _http.get(
        Uri.parse('https://open.spotify.com/embed/$type/${link.id}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/139.0 Safari/537.36',
          'Accept-Language': 'en',
        }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Spotify answered ${response.statusCode}');
    }
    final tracks = parse(response.body, link, addedBy: addedBy, newId: newId);
    if (tracks.isEmpty) throw StateError('No songs found on that Spotify page');
    return tracks;
  }

  /// Tracks in an embed page's `__NEXT_DATA__`.
  static List<DjTrack> parse(String html, DjLink link,
      {required String addedBy, required String Function() newId}) {
    final match = RegExp(
            r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',
            dotAll: true)
        .firstMatch(html);
    if (match == null) return const [];
    final Object? data;
    try {
      data = jsonDecode(match[1]!);
    } catch (_) {
      return const [];
    }
    final entity = _path(data, ['props', 'pageProps', 'state', 'data', 'entity']);
    if (entity is! Map) return const [];

    final cover = _coverOf(entity);
    if (entity['type'] == 'track') {
      final title = entity['name'] ?? entity['title'];
      if (title is! String) return const [];
      final artists = entity['artists'] is List
          ? (entity['artists'] as List)
              .whereType<Map>()
              .map((a) => a['name'])
              .whereType<String>()
              .join(', ')
          : null;
      return [
        _track(title, artists, entity['duration'], link.url, cover, addedBy,
            newId)
      ];
    }

    final list = entity['trackList'];
    if (list is! List) return const [];
    // An album's tracks share its cover; a playlist's don't, and the page
    // has no per-track art.
    final shared = entity['type'] == 'album' ? cover : null;
    return [
      for (final item in list.whereType<Map>())
        if (item['title'] is String)
          _track(
              item['title'] as String,
              item['subtitle'] is String ? item['subtitle'] as String : null,
              item['duration'],
              _trackUrl(item['uri']) ?? link.url,
              shared,
              addedBy,
              newId),
    ];
  }

  static DjTrack _track(String title, String? artists, Object? duration,
      String link, String? thumbnail, String addedBy, String Function() newId) {
    final artist = artists?.trim().isEmpty ?? true ? null : artists!.trim();
    return DjTrack(
      id: newId(),
      // Played from YouTube: the best match for "artist - title".
      source: 'ytsearch1:${artist != null ? '$artist - ' : ''}$title',
      link: link,
      kind: DjSource.spotify,
      title: title,
      artist: artist,
      durationMs: duration is num && duration > 0 ? duration.toInt() : null,
      thumbnail: thumbnail,
      addedBy: addedBy,
    );
  }

  static String? _trackUrl(Object? uri) {
    if (uri is! String || !uri.startsWith('spotify:track:')) return null;
    return 'https://open.spotify.com/track/${uri.substring(14)}';
  }

  static String? _coverOf(Map entity) {
    final sources = _path(entity, ['coverArt', 'sources']) ??
        _path(entity, ['visualIdentity', 'image']);
    if (sources is! List) return null;
    // The one closest to what the booth shows (~300 px).
    String? best;
    num bestDistance = double.infinity;
    for (final source in sources.whereType<Map>()) {
      final url = source['url'];
      final width = source['width'] is num ? source['width'] as num : 0;
      final distance = (width - 300).abs();
      if (url is String && distance < bestDistance) {
        best = url;
        bestDistance = distance;
      }
    }
    return best;
  }

  static Object? _path(Object? json, List<String> keys) {
    Object? node = json;
    for (final key in keys) {
      if (node is! Map) return null;
      node = node[key];
    }
    return node;
  }
}
