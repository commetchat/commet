import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../video_capabilities.dart';
import '../video_embed_info.dart';
import '../video_playback_source.dart';
import '../video_provider.dart';

class YouTubeProvider implements VideoProvider {
  YouTubeProvider({http.Client? httpClient}) : _defaultHttpClient = httpClient;

  final http.Client? _defaultHttpClient;

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube';

  @override
  VideoCapabilities get capabilities => VideoCapabilities.officialEmbed;

  static final RegExp _youtubeDomainRegex = RegExp(
    r'^(?:(?:www|m)\.)?(?:youtube\.com|youtu\.be)$',
    caseSensitive: false,
  );

  @override
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!_youtubeDomainRegex.hasMatch(host)) return false;

    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) return true;

    if (uri.pathSegments.isNotEmpty) {
      final first = uri.pathSegments.first.toLowerCase();
      if (first == 'watch' ||
          first == 'shorts' ||
          first == 'embed' ||
          first == 'live') {
        return true;
      }
    }

    return uri.queryParameters.containsKey('v');
  }

  bool isShorts(Uri uri) =>
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first.toLowerCase() == 'shorts';

  String? extractVideoId(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    if (uri.pathSegments.isNotEmpty) {
      final first = uri.pathSegments.first.toLowerCase();
      if ((first == 'shorts' || first == 'embed' || first == 'live') &&
          uri.pathSegments.length > 1) {
        return uri.pathSegments[1];
      }
    }

    return uri.queryParameters['v'];
  }

  @override
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    final videoId = extractVideoId(uri);
    if (videoId == null || videoId.isEmpty) return null;

    final shorts = isShorts(uri);
    final aspectRatio = shorts ? (9.0 / 16.0) : (16.0 / 9.0);
    final platformName = shorts ? 'YouTube Shorts' : 'YouTube';

    final playbackSource = fetchPlayback
        ? OfficialVideoEmbedSource(
            Uri.https('www.youtube-nocookie.com', '/embed/$videoId', const {
              'autoplay': '1',
              'enablejsapi': '1',
              'playsinline': '1',
              'rel': '0',
              'controls': '1',
              'fs': '1',
            }),
            provider: OfficialVideoProvider.youtube,
          )
        : null;

    final httpClient = client ?? _defaultHttpClient ?? http.Client();
    final shouldCloseClient = client == null && _defaultHttpClient == null;

    String? title;
    String? author;
    String? thumbnailUrl;

    try {
      final oembedUrl = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$videoId',
        'format': 'json',
      });
      final response =
          await httpClient.get(oembedUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        title = data['title'] as String?;
        author = data['author_name'] as String?;
        thumbnailUrl = data['thumbnail_url'] as String?;
      }
    } catch (_) {
      // Fallback below
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }

    thumbnailUrl ??= 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    title ??= shorts ? 'YouTube Shorts' : 'YouTube Video';

    return VideoEmbedInfo(
      originalUrl: uri,
      title: title,
      author: author,
      thumbnailUrl: thumbnailUrl,
      thumbnail: NetworkImage(thumbnailUrl),
      aspectRatio: aspectRatio,
      platformName: platformName,
      isShortForm: shorts,
      playbackSource: playbackSource,
      capabilities: capabilities,
    );
  }
}
