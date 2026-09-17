import 'video_capabilities.dart';

/// A playable capability resolved for a video preview.
sealed class VideoPlaybackSource {
  const VideoPlaybackSource();

  VideoCapabilities get capabilities;
}

/// Media that Commet can play natively through media_kit.
final class NativeVideoSource extends VideoPlaybackSource {
  const NativeVideoSource(
    this.uri, {
    this.httpHeaders = const {},
    this.customCapabilities,
  });

  final Uri uri;
  final Map<String, String> httpHeaders;
  final VideoCapabilities? customCapabilities;

  @override
  VideoCapabilities get capabilities =>
      customCapabilities ?? VideoCapabilities.native;
}

enum OfficialVideoProvider {
  youtube,
  instagram,
  vimeo,
  other,
}

/// Provider-owned playback rendered inside Commet's video modal.
final class OfficialVideoEmbedSource extends VideoPlaybackSource {
  const OfficialVideoEmbedSource(
    this.uri, {
    required this.provider,
    this.customCapabilities,
  });

  final Uri uri;
  final OfficialVideoProvider provider;
  final VideoCapabilities? customCapabilities;

  @override
  VideoCapabilities get capabilities =>
      customCapabilities ?? VideoCapabilities.officialEmbed;
}
