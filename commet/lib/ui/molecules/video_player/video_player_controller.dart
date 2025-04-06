import 'dart:async';
import 'dart:typed_data';

import 'package:commet/cache/file_provider.dart';
import 'package:flutter/material.dart';

class VideoPlayerController {
  Future<void> Function()? _onPause;

  Future<void> Function()? _onPlay;

  Future<void> Function()? _onReplay;

  Future<void> Function(Duration percent)? _seekTo;

  Future<Uint8List?> Function()? _screenshot;

  Future<Size?> Function()? _getSize;

  Future<Duration> Function()? _getLength;

  final StreamController<bool> _isBuffering = StreamController.broadcast();

  final StreamController<DownloadProgress> _downloadProgress =
      StreamController.broadcast();

  final StreamController<bool> _isCompleted = StreamController.broadcast();

  final StreamController<Duration> _onProgressed = StreamController.broadcast();

  Stream<bool> get isBuffering => _isBuffering.stream;

  Stream<bool> get isCompleted => _isCompleted.stream;

  Stream<Duration> get onProgressed => _onProgressed.stream;

  Stream<DownloadProgress> get onDownloadProgressed => _downloadProgress.stream;

  void attach(
      {required Future<void> Function() pause,
      required Future<void> Function() play,
      required Future<void> Function() replay,
      required Future<Duration> Function() getLength,
      required Future<Size?> Function() getSize,
      Future<Uint8List?> Function()? screenshot,
      required Future<void> Function(Duration percent) seekTo}) {
    _onPause = pause;
    _onPlay = play;
    _onReplay = replay;
    _seekTo = seekTo;
    _getLength = getLength;
    _screenshot = screenshot;
    _getSize = getSize;
  }

  Future<void> pause() async {
    await _onPause!.call();
  }

  Future<void> play() async {
    await _onPlay?.call();
  }

  Future<void> replay() async {
    await _onReplay!.call();
  }

  Future<void> seekTo(Duration duration) async {
    await _seekTo!.call(duration);
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

  void setCompleted(bool isBuffering) {
    _isCompleted.add(isBuffering);
  }

  void setProgress(Duration progress) {
    _onProgressed.add(progress);
  }

  Future<Duration> getLength() async {
    return await _getLength!.call();
  }

  Future<Size?> getSize() async {
    return await _getSize!.call();
  }
}
