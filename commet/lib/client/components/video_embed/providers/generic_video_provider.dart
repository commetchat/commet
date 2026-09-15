import 'package:http/http.dart' as http;

import '../video_capabilities.dart';
import '../video_embed_info.dart';
import '../video_playback_source.dart';
import '../video_provider.dart';

class GenericVideoProvider implements VideoProvider {
  static const Set<String> _videoExtensions = {
    '.mp4',
    '.m4v',
    '.webm',
    '.mkv',
    '.mov',
    '.avi',
    '.m3u8',
  };

  @override
  String get id => 'generic';

  @override
  String get name => 'Video';

  @override
  VideoCapabilities get capabilities => VideoCapabilities.native;

  @override
  bool canHandle(Uri uri) {
    final path = uri.path.toLowerCase();
    for (final ext in _videoExtensions) {
      if (path.endsWith(ext)) return true;
    }
    return false;
  }

  @override
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    if (!canHandle(uri)) return null;

    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Video';

    return VideoEmbedInfo(
      originalUrl: uri,
      title: fileName,
      streamUrl: uri,
      playbackSource: NativeVideoSource(uri),
      aspectRatio: 16.0 / 9.0,
      platformName: 'Video',
      isShortForm: false,
      capabilities: capabilities,
    );
  }
}
