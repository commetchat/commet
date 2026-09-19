// Recognises the links the DJ can queue. Pure string work, shared by the
// add bar (to say what a pasted link is before resolving it) and the
// resolver.
import 'package:commet/client/components/dj/dj_models.dart';

enum DjLinkType {
  youtubeVideo,
  youtubePlaylist,
  soundcloudTrack,
  soundcloudSet,
  spotifyTrack,
  spotifyAlbum,
  spotifyPlaylist,

  /// Any other http(s) link: yt-dlp may still know it.
  other,
}

class DjLink {
  final DjLinkType type;

  /// The link, normalised: `https://`, no tracking parameters.
  final String url;

  /// Video, track, album or playlist id where the link has one.
  final String? id;

  const DjLink(this.type, this.url, {this.id});

  DjSource get source => switch (type) {
        DjLinkType.youtubeVideo || DjLinkType.youtubePlaylist => DjSource.youtube,
        DjLinkType.soundcloudTrack ||
        DjLinkType.soundcloudSet =>
          DjSource.soundcloud,
        DjLinkType.spotifyTrack ||
        DjLinkType.spotifyAlbum ||
        DjLinkType.spotifyPlaylist =>
          DjSource.spotify,
        DjLinkType.other => DjSource.other,
      };

  bool get isCollection => switch (type) {
        DjLinkType.youtubePlaylist ||
        DjLinkType.soundcloudSet ||
        DjLinkType.spotifyAlbum ||
        DjLinkType.spotifyPlaylist =>
          true,
        _ => false,
      };

  @override
  String toString() => 'DjLink($type, $url)';
}

class DjLinks {
  static final RegExp _urlPattern = RegExp(r'https?://[^\s<>"]+');
  static final RegExp _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Every link in [text] (pasted text can hold several, one per line),
  /// in order, without duplicates. Bare `youtube.com/...` style links without
  /// a scheme count too.
  static List<DjLink> parseAll(String text) {
    final found = <DjLink>[];
    final seen = <String>{};
    final withScheme = text.replaceAllMapped(
        RegExp(r'(^|\s)((?:www\.|m\.|music\.)?(?:youtube\.com|youtu\.be|soundcloud\.com|open\.spotify\.com|on\.soundcloud\.com)/)'),
        (m) => '${m[1]}https://${m[2]}');
    for (final match in _urlPattern.allMatches(withScheme)) {
      final link = parse(_trimPunctuation(match[0]!));
      if (link != null && seen.add(link.url)) found.add(link);
    }
    return found;
  }

  static String _trimPunctuation(String url) =>
      url.replaceFirst(RegExp(r'[).,;!?\]]+$'), '');

  /// What [input] links to; null when it is not an http(s) link.
  static DjLink? parse(String input) {
    try {
      return _parse(input);
    } on FormatException {
      // Malformed percent-encoding in the query or path.
      return null;
    }
  }

  static DjLink? _parse(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    if (uri.host.isEmpty) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (host == 'youtu.be' && segments.isNotEmpty) {
      final id = segments.first;
      if (_youtubeId.hasMatch(id)) return _youtubeVideo(id);
    }

    if (host == 'youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com') {
      final v = uri.queryParameters['v'];
      final list = uri.queryParameters['list'];
      // A video opened from a playlist plays that video, like a player
      // would. The playlist page itself queues the whole list.
      if (v != null && _youtubeId.hasMatch(v)) return _youtubeVideo(v);
      if (segments.isNotEmpty &&
          const ['shorts', 'live', 'embed', 'v'].contains(segments.first) &&
          segments.length > 1 &&
          _youtubeId.hasMatch(segments[1])) {
        return _youtubeVideo(segments[1]);
      }
      if (list != null && list.isNotEmpty) {
        return DjLink(DjLinkType.youtubePlaylist,
            'https://www.youtube.com/playlist?list=$list',
            id: list);
      }
      return null;
    }

    if (host == 'soundcloud.com' || host == 'on.soundcloud.com') {
      if (host == 'on.soundcloud.com') {
        // Short share links redirect; yt-dlp follows them.
        return DjLink(DjLinkType.soundcloudTrack, _clean(uri).toString());
      }
      if (segments.length >= 3 && segments[1] == 'sets') {
        return DjLink(DjLinkType.soundcloudSet,
            'https://soundcloud.com/${segments[0]}/sets/${segments[2]}');
      }
      if (segments.length >= 2 &&
          !const ['you', 'discover', 'stream', 'search', 'charts']
              .contains(segments[0])) {
        return DjLink(DjLinkType.soundcloudTrack,
            'https://soundcloud.com/${segments[0]}/${segments[1]}');
      }
      return null;
    }

    if (host == 'open.spotify.com') {
      if (segments.isEmpty) return null;
      // Localised links: /intl-de/track/...
      final parts = segments.first.startsWith('intl-')
          ? segments.skip(1).toList()
          : segments;
      if (parts.length >= 2) {
        final id = parts[1];
        final type = switch (parts[0]) {
          'track' => DjLinkType.spotifyTrack,
          'album' => DjLinkType.spotifyAlbum,
          'playlist' => DjLinkType.spotifyPlaylist,
          _ => null,
        };
        if (type != null && RegExp(r'^[A-Za-z0-9]{22}$').hasMatch(id)) {
          return DjLink(type, 'https://open.spotify.com/${parts[0]}/$id',
              id: id);
        }
      }
      return null;
    }

    return DjLink(DjLinkType.other, _clean(uri).toString());
  }

  static DjLink _youtubeVideo(String id) => DjLink(
      DjLinkType.youtubeVideo, 'https://www.youtube.com/watch?v=$id',
      id: id);

  static Uri _clean(Uri uri) {
    final query = Map.of(uri.queryParameters)
      ..removeWhere((k, _) => k.startsWith('utm_') || k == 'si');
    return uri.replace(
        scheme: 'https', queryParameters: query.isEmpty ? null : query);
  }

  /// YouTube thumbnail of a video id, without asking YouTube.
  static String youtubeThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  /// The YouTube video id in [url], if it is a YouTube video link.
  static String? youtubeVideoId(String url) {
    final link = parse(url);
    return link?.type == DjLinkType.youtubeVideo ? link!.id : null;
  }
}
