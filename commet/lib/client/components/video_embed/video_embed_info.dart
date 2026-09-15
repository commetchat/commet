import 'package:flutter/widgets.dart';

import 'video_capabilities.dart';
import 'video_playback_source.dart';

/// Encapsulates metadata and direct stream information for an embedded video.
class VideoEmbedInfo {
  final Uri originalUrl;
  final String title;
  final String? author;
  final String? description;
  final String? thumbnailUrl;
  final ImageProvider? thumbnail;
  final Uri? streamUrl;
  final VideoPlaybackSource? playbackSource;
  final double? aspectRatio;
  final Duration? duration;
  final String platformName;
  final bool isShortForm;
  final VideoCapabilities capabilities;

  const VideoEmbedInfo({
    required this.originalUrl,
    required this.title,
    this.author,
    this.description,
    this.thumbnailUrl,
    this.thumbnail,
    this.streamUrl,
    this.playbackSource,
    this.aspectRatio,
    this.duration,
    required this.platformName,
    this.isShortForm = false,
    this.capabilities = const VideoCapabilities(),
  });

  VideoCapabilities get effectiveCapabilities =>
      playbackSource?.capabilities ?? capabilities;

  VideoEmbedInfo copyWith({
    Uri? originalUrl,
    String? title,
    String? author,
    String? description,
    String? thumbnailUrl,
    ImageProvider? thumbnail,
    Uri? streamUrl,
    VideoPlaybackSource? playbackSource,
    double? aspectRatio,
    Duration? duration,
    String? platformName,
    bool? isShortForm,
    VideoCapabilities? capabilities,
  }) {
    return VideoEmbedInfo(
      originalUrl: originalUrl ?? this.originalUrl,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      streamUrl: streamUrl ?? this.streamUrl,
      playbackSource: playbackSource ?? this.playbackSource,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      duration: duration ?? this.duration,
      platformName: platformName ?? this.platformName,
      isShortForm: isShortForm ?? this.isShortForm,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}
