import 'package:http/http.dart' as http;

import 'providers/generic_video_provider.dart';
import 'providers/instagram_provider.dart';
import 'providers/twitter_provider.dart';
import 'providers/youtube_provider.dart';
import 'video_embed_info.dart';
import 'video_provider.dart';

/// Composite registry coordinating multiple video providers.
class CompositeVideoProvider {
  final List<VideoProvider> _providers;

  CompositeVideoProvider({List<VideoProvider>? providers})
      : _providers = providers ??
            [
              YouTubeProvider(),
              TwitterProvider(),
              InstagramProvider(),
              GenericVideoProvider(),
            ];

  static final CompositeVideoProvider instance = CompositeVideoProvider();

  List<VideoProvider> get providers => List.unmodifiable(_providers);

  /// Registers a new provider, prepending it to prioritize specialized implementations.
  void registerProvider(VideoProvider provider) {
    _providers.insert(0, provider);
  }

  bool canHandle(Uri uri) {
    for (final provider in _providers) {
      if (provider.canHandle(uri)) return true;
    }
    return false;
  }

  VideoProvider? findProvider(Uri uri) {
    for (final provider in _providers) {
      if (provider.canHandle(uri)) return provider;
    }
    return null;
  }

  Future<VideoEmbedInfo?> resolve(
    Uri uri, {
    bool fetchPlayback = false,
    http.Client? client,
  }) async {
    final provider = findProvider(uri);
    if (provider == null) return null;
    return await provider.resolve(uri,
        fetchPlayback: fetchPlayback, client: client);
  }
}
