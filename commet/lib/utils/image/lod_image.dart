import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

enum LODImageType {
  blurhash,
  thumbnail,
  fullres,
}

class LODImageProvider extends ImageProvider<LODImageProvider> {
  LODImageProvider(
      {this.blurhash,
      this.loadThumbnail,
      this.loadFullRes,
      this.autoLoadFullRes = true});
  String? blurhash;
  bool autoLoadFullRes;
  Future<Uint8List?> Function()? loadThumbnail;
  Future<Uint8List?> Function()? loadFullRes;
  LODImageCompleter? completer;

  @override
  Future<LODImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LODImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      LODImageProvider key, DecoderBufferCallback decode) {
    completer = LODImageCompleter(
        blurhash: blurhash,
        loadThumbnail: loadThumbnail,
        loadFullRes: loadFullRes,
        autoLoadFullRes: autoLoadFullRes);
    return completer!;
  }

  void fetchFullRes() {
    completer?.fetchFullRes();
  }
}

class LODImageCompleter extends ImageStreamCompleter {
  String? blurhash;
  Future<Uint8List?> Function()? loadThumbnail;
  Future<Uint8List?> Function()? loadFullRes;
  LODImageType? currentlyLoadedImage;
  late double _scale;
  ImageInfo? currentImage;
  FrameInfo? _nextFrame;
  Codec? _codec;
  late Duration _shownTimestamp;
  Duration? _frameDuration;
  bool _frameCallbackScheduled = false;

  int _framesEmitted = 0;
  Timer? _timer;
  bool _isFullResLoading = false;

  LODImageCompleter(
      {this.blurhash,
      this.loadThumbnail,
      this.loadFullRes,
      double scale = 1,
      bool autoLoadFullRes = true}) {
    if (blurhash != null) _loadBlurhash();
    if (loadThumbnail != null) _loadThumbnail();
    if (loadFullRes != null && autoLoadFullRes) _loadFullRes();
    _scale = scale;
  }

  Future<void> _loadBlurhash() async {
    var image =
        await blurHashDecodeImage(blurHash: blurhash!, width: 10, height: 10);

    if (currentlyLoadedImage == null) {
      currentlyLoadedImage = LODImageType.blurhash;
      setImage(ImageInfo(image: image));
    }
  }

  Future<void> _loadThumbnail() async {
    var bytes = await loadThumbnail!.call();
    if (bytes == null) return;

    var codec = await instantiateImageCodec(bytes);

    _setCodec(LODImageType.thumbnail, codec);
  }

  Future<void> fetchFullRes() async {
    return _loadFullRes();
  }

  Future<void> _loadFullRes() async {
    if (_isFullResLoading) return;
    _isFullResLoading = true;
    var bytes = await loadFullRes!.call();
    if (bytes == null) return;

    var codec = await instantiateImageCodec(bytes);
    _setCodec(LODImageType.fullres, codec);
  }

  void _setCodec(LODImageType type, Codec codec) {
    if (type.index > (currentlyLoadedImage?.index ?? -1)) {
      _codec = codec;
      currentlyLoadedImage = type;
      _decodeNextFrameAndSchedule();
    }
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    _nextFrame?.image.dispose();
    _nextFrame = null;

    _nextFrame = await _codec!.getNextFrame();

    if (_codec!.frameCount == 1) {
      _emitFrame(ImageInfo(
        image: _nextFrame!.image.clone(),
        scale: _scale,
        debugLabel: debugLabel,
      ));

      _nextFrame!.image.dispose();
      _nextFrame = null;
      return;
    }

    _scheduleAppFrame();
  }

  void _scheduleAppFrame() {
    if (_frameCallbackScheduled) {
      return;
    }
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners) {
      return;
    }
    assert(_nextFrame != null);
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(
        image: _nextFrame!.image.clone(),
        scale: _scale,
        debugLabel: debugLabel,
      ));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame!.duration;
      _nextFrame!.image.dispose();
      _nextFrame = null;
      final int completedCycles = _framesEmitted ~/ _codec!.frameCount;
      if (_codec!.repetitionCount == -1 ||
          completedCycles <= _codec!.repetitionCount) {
        _decodeNextFrameAndSchedule();
      }
      return;
    }
    final Duration delay = _frameDuration! - (timestamp - _shownTimestamp);
    _timer = Timer(delay * timeDilation, () {
      _scheduleAppFrame();
    });
  }

  @override
  void addListener(ImageStreamListener listener) {
    if (!hasListeners &&
        _codec != null &&
        (currentImage == null || _codec!.frameCount > 1)) {
      _decodeNextFrameAndSchedule();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }

  bool _isFirstFrame() {
    return _frameDuration == null;
  }

  bool _hasFrameDurationPassed(Duration timestamp) {
    return timestamp - _shownTimestamp >= _frameDuration!;
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }
}
