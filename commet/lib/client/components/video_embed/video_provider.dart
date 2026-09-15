import 'package:http/http.dart' as http;

import 'video_capabilities.dart';
import 'video_embed_info.dart';

/// Seam interface for modular media providers.
abstract class VideoProvider {
  /// Unique identifier of this provider (e.g. 'youtube', 'twitter', 'instagram').
  String get id;

  /// User-friendly name of the platform (e.g. 'YouTube', 'X (Twitter)', 'Instagram Reels').
  String get name;

  /// Base capabilities supported by this provider.
  VideoCapabilities get capabilities;

  /// Returns whether this provider can handle the given URL.
  bool canHandle(Uri uri);

  /// Resolves metadata and, when [fetchPlayback] is true, the actual playable capability.
  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  });
}
