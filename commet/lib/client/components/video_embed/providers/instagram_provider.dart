import 'package:http/http.dart' as http;

import '../video_capabilities.dart';
import '../video_embed_info.dart';
import '../video_playback_source.dart';
import '../video_provider.dart';

class InstagramPostInfo {
  final String shortcode;
  final bool isReel;

  const InstagramPostInfo({required this.shortcode, required this.isReel});
}

class InstagramProvider implements VideoProvider {
  @override
  String get id => 'instagram';

  @override
  String get name => 'Instagram';

  @override
  VideoCapabilities get capabilities => VideoCapabilities.officialEmbed;

  static final RegExp _instagramDomainRegex = RegExp(
    r'^(?:(?:www|m)\.)?instagram\.com$',
    caseSensitive: false,
  );

  @override
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!_instagramDomainRegex.hasMatch(host)) return false;

    return extractPostInfo(uri) != null;
  }

  InstagramPostInfo? extractPostInfo(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2) {
      final type = segments[0].toLowerCase();
      if (type == 'reel' || type == 'p' || type == 'tv') {
        final code = segments[1];
        return InstagramPostInfo(
          shortcode: code,
          isReel: type == 'reel',
        );
      }
    }
    return null;
  }

  @override
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    final info = extractPostInfo(uri);
    if (info == null) return null;

    final isReel = info.isReel;
    final double defaultAspect = isReel ? (9.0 / 16.0) : 1.0;
    final platformName = isReel ? 'Instagram Reels' : 'Instagram';

    return VideoEmbedInfo(
      originalUrl: uri,
      title: isReel ? 'Instagram Reel' : 'Instagram Video',
      aspectRatio: defaultAspect,
      platformName: platformName,
      isShortForm: isReel,
      playbackSource: fetchPlayback
          ? OfficialVideoEmbedSource(
              Uri.https(
                'www.instagram.com',
                '/${isReel ? 'reel' : 'p'}/${info.shortcode}/embed/',
              ),
              provider: OfficialVideoProvider.instagram,
            )
          : null,
      capabilities: capabilities,
    );
  }
}
