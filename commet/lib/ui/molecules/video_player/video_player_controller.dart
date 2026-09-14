import 'dart:async';
import 'dart:typed_data';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/client/components/video_embed/video_capabilities.dart';
import 'package:flutter/material.dart';

class VideoQualityOption {
  const VideoQualityOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoQualityOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label;

  @override
  int get hashCode => Object.hash(id, label);
}

class VideoSubtitleOption {
  const VideoSubtitleOption({
    required this.id,
    required this.label,
    this.language,
  });

  final String id;
  final String label;
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoSubtitleOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          language == other.language;

  @override
  int get hashCode => Object.hash(id, label, language);
}

class VideoPlayerSettings {
  const VideoPlayerSettings({
    this.volume = 100.0,
    this.lastNonZeroVolume = 100.0,
    this.rate = 1.0,
    this.qualities = const [],
    this.selectedQualityId,
    this.subtitles = const [],
    this.selectedSubtitleId = 'no',
    this.playing = false,
    this.capabilities = VideoCapabilities.native,
  });

  final double volume;
  final double lastNonZeroVolume;
  final double rate;
  final List<VideoQualityOption> qualities;
  final String? selectedQualityId;
  final List<VideoSubtitleOption> subtitles;
  final String? selectedSubtitleId;
  final bool playing;
  final VideoCapabilities capabilities;

  bool get isMuted => volume == 0.0;

  VideoPlayerSettings copyWith({
    double? volume,
    double? lastNonZeroVolume,
    double? rate,
    List<VideoQualityOption>? qualities,
    String? selectedQualityId,
    List<VideoSubtitleOption>? subtitles,
    String? selectedSubtitleId,
    bool? playing,
    VideoCapabilities? capabilities,
  }) {
    return VideoPlayerSettings(
      volume: volume ?? this.volume,
      lastNonZeroVolume: lastNonZeroVolume ?? this.lastNonZeroVolume,
      rate: rate ?? this.rate,
      qualities: qualities ?? this.qualities,
      selectedQualityId: selectedQualityId ?? this.selectedQualityId,
      subtitles: subtitles ?? this.subtitles,
      selectedSubtitleId: selectedSubtitleId ?? this.selectedSubtitleId,
      playing: playing ?? this.playing,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}

class VideoPlayerController {
  VideoPlayerController({
    VideoPlayerSettings initialSettings = const VideoPlayerSettings(),
  }) : _settings = initialSettings;

  Future<void> Function()? _onPause;
  Future<void> Function()? _onPlay;
  Future<void> Function()? _onReplay;
  Future<void> Function(Duration duration)? _seekTo;
  Future<Uint8List?> Function()? _screenshot;
  Future<Size?> Function()? _getSize;
  Future<Duration> Function()? _getLength;

  Future<void> Function(double volume)? _setVolume;
  Future<void> Function(double rate)? _setRate;
  Future<void> Function(String id)? _selectVideoTrack;
  Future<void> Function(String id)? _selectSubtitleTrack;
  Future<void> Function()? _enterFullscreen;
  Future<void> Function()? _exitFullscreen;

  final StreamController<bool> _isBuffering = StreamController.broadcast();
  final StreamController<DownloadProgress> _downloadProgress =
      StreamController.broadcast();
  final StreamController<bool> _isCompleted = StreamController.broadcast();
  final StreamController<Duration> _onProgressed = StreamController.broadcast();
  final StreamController<String> _onError = StreamController.broadcast();
  final StreamController<VideoPlayerSettings> _settingsController =
      StreamController.broadcast();

  VideoPlayerSettings _settings;

  Stream<bool> get isBuffering => _isBuffering.stream;
  Stream<bool> get isCompleted => _isCompleted.stream;
  Stream<Duration> get onProgressed => _onProgressed.stream;
  Stream<DownloadProgress> get onDownloadProgressed => _downloadProgress.stream;
  Stream<String> get onError => _onError.stream;
  Stream<VideoPlayerSettings> get onSettingsChanged => _settingsController.stream;

  VideoPlayerSettings get settings => _settings;

  void attach({
    required Future<void> Function() pause,
    required Future<void> Function() play,
    required Future<void> Function() replay,
    required Future<Duration> Function() getLength,
    required Future<Size?> Function() getSize,
    Future<Uint8List?> Function()? screenshot,
    required Future<void> Function(Duration duration) seekTo,
    Future<void> Function(double volume)? setVolume,
    Future<void> Function(double rate)? setRate,
    Future<void> Function(String id)? selectVideoTrack,
    Future<void> Function(String id)? selectSubtitleTrack,
    Future<void> Function()? enterFullscreen,
    Future<void> Function()? exitFullscreen,
  }) {
    _onPause = pause;
    _onPlay = play;
    _onReplay = replay;
    _seekTo = seekTo;
    _getLength = getLength;
    _screenshot = screenshot;
    _getSize = getSize;
    _setVolume = setVolume;
    _setRate = setRate;
    _selectVideoTrack = selectVideoTrack;
    _selectSubtitleTrack = selectSubtitleTrack;
    _enterFullscreen = enterFullscreen;
    _exitFullscreen = exitFullscreen;
  }

  void updateSettings({
    double? volume,
    double? lastNonZeroVolume,
    double? rate,
    List<VideoQualityOption>? qualities,
    String? selectedQualityId,
    List<VideoSubtitleOption>? subtitles,
    String? selectedSubtitleId,
    bool? playing,
    VideoCapabilities? capabilities,
  }) {
    _settings = _settings.copyWith(
      volume: volume,
      lastNonZeroVolume: lastNonZeroVolume,
      rate: rate,
      qualities: qualities,
      selectedQualityId: selectedQualityId,
      subtitles: subtitles,
      selectedSubtitleId: selectedSubtitleId,
      playing: playing,
      capabilities: capabilities,
    );
    _settingsController.add(_settings);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 100.0);
    final lastNonZero =
        clamped > 0 ? clamped : _settings.lastNonZeroVolume;
    updateSettings(volume: clamped, lastNonZeroVolume: lastNonZero);
    await _setVolume?.call(clamped);
  }

  Future<void> toggleMute() async {
    if (_settings.isMuted) {
      final target =
          _settings.lastNonZeroVolume > 0 ? _settings.lastNonZeroVolume : 100.0;
      await setVolume(target);
    } else {
      await setVolume(0.0);
    }
  }

  Future<void> setRate(double rate) async {
    updateSettings(rate: rate);
    await _setRate?.call(rate);
  }

  Future<void> selectVideoTrack(String id) async {
    updateSettings(selectedQualityId: id);
    await _selectVideoTrack?.call(id);
  }

  Future<void> selectSubtitleTrack(String id) async {
    updateSettings(selectedSubtitleId: id);
    await _selectSubtitleTrack?.call(id);
  }

  Future<void> enterFullscreen() async {
    await _enterFullscreen?.call();
  }

  Future<void> exitFullscreen() async {
    await _exitFullscreen?.call();
  }

  Future<void> pause() async {
    updateSettings(playing: false);
    await _onPause?.call();
  }

  Future<void> play() async {
    updateSettings(playing: true);
    await _onPlay?.call();
  }

  Future<void> replay() async {
    updateSettings(playing: true);
    await _onReplay?.call();
  }

  Future<void> seekTo(Duration duration) async {
    await _seekTo?.call(duration);
  }

  Future<Uint8List?> screenshot() async {
    return _screenshot?.call();
  }

  void setBuffering(bool isBuffering) {
    _isBuffering.add(isBuffering);
  }

  void setBufferingProgress(DownloadProgress progress) {
    _downloadProgress.add(progress);
  }

  void setCompleted(bool isCompleted) {
    _isCompleted.add(isCompleted);
    if (isCompleted) {
      updateSettings(playing: false);
    }
  }

  void setProgress(Duration progress) {
    _onProgressed.add(progress);
  }

  void setError(dynamic error) {
    _onError.add(error.toString());
  }

  Future<Duration> getLength() async {
    if (_getLength == null) return Duration.zero;
    return await _getLength!.call();
  }

  Future<Size?> getSize() async {
    return await _getSize?.call();
  }

  void dispose() {
    _isBuffering.close();
    _downloadProgress.close();
    _isCompleted.close();
    _onProgressed.close();
    _onError.close();
    _settingsController.close();
  }
}
