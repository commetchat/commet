import 'dart:async';
import 'dart:ui';

import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

enum LODImageType {
  blurhash,
  thumbnail,
  fullres,
}

class LODImageProvider extends ImageProvider<String> {
  LODImageProvider(
      {this.blurhash,
      this.loadThumbnail,
      this.loadFullRes,
      this.thumbnailHeight,
      required this.id,
      this.fullResHeight,
      this.autoLoadFullRes = true});
  String id;
  String? blurhash;
  String? get mimeType => completer?.mimeType;
  bool autoLoadFullRes;
  Future<Uint8List?> Function()? loadThumbnail;
  Future<Uint8List?> Function()? loadFullRes;
  LODImageCompleter? completer;
  int? thumbnailHeight;
  int? fullResHeight;

  Future<bool> hasCachedFullres() async {
    return false;
  }

  Future<bool> hasCachedThumbnail() async {
    return false;
  }

  @override
  Future<String> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<String>(id);
  }

  @override
  void resolveStreamForKey(ImageConfiguration configuration, ImageStream stream,
      String key, ImageErrorListener handleError) {
    super.resolveStreamForKey(configuration, stream, key, handleError);

    completer = stream.completer as LODImageCompleter;
  }

  @override
  ImageStreamCompleter loadImage(String key, ImageDecoderCallback decode) {
    completer = LODImageCompleter(
        blurhash: blurhash,
        loadThumbnail: loadThumbnail,
        loadFullRes: loadFullRes,
        callback: decode,
        hasCachedFullres: hasCachedFullres,
        hasCachedThumbnail: hasCachedThumbnail,
        thumbnailHeight: thumbnailHeight,
        fullResHeight: fullResHeight,
        autoLoadFullres: autoLoadFullRes);
    return completer!;
  }

  Future<void> fetchThumbnail() async {
    if (completer == null) {
      ImageUtils.imageProviderToImage(this);
    }

    await completer?.fetchThumbnail();
  }

  Future<void> fetchFullRes() async {
    if (completer == null) {
      ImageUtils.imageProviderToImage(this);
    }

    await completer?.fetchFullRes();
  }
}

class LODImageCompleter extends ImageStreamCompleter {
  String? blurhash;
  Future<bool> Function()? hasCachedThumbnail;
  Future<bool> Function()? hasCachedFullres;
  Future<Uint8List?> Function()? loadThumbnail;
  Future<Uint8List?> Function()? loadFullRes;
  LODImageType? currentlyLoadedImage;
  final double _scale = 1;
  ImageInfo? currentImage;
  FrameInfo? _nextFrame;
  Codec? _codec;
  late Duration _shownTimestamp;
  ImageDecoderCallback callback;
  Duration? _frameDuration;
  bool _frameCallbackScheduled = false;
  bool autoLoadFullres;
  String? mimeType;
  int _framesEmitted = 0;
  int? thumbnailHeight;
  int? fullResHeight;
  double scale = 1;
  Timer? _timer;
  Future? fullResLoading = null;
  Future? thumbnailLoading = null;

  LODImageCompleter(
      {this.blurhash,
      required this.callback,
      this.loadThumbnail,
      this.loadFullRes,
      this.hasCachedFullres,
      this.hasCachedThumbnail,
      this.thumbnailHeight,
      this.fullResHeight,
      this.autoLoadFullres = true}) {
    loadImages();
  }

  Future<void> loadImages() async {
    if (loadFullRes != null &&
        autoLoadFullres &&
        hasCachedFullres != null &&
        await (hasCachedFullres!.call()) == true) {
      _loadFullRes();
      return;
    }

    if (loadThumbnail != null &&
        hasCachedThumbnail != null &&
        await (hasCachedThumbnail!.call()) == true) {
      _loadThumbnail();
      return;
    }

    if (blurhash != null) _loadBlurhash();
    if (loadThumbnail != null) _loadThumbnail();
    if (loadFullRes != null && autoLoadFullres) _loadFullRes();
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
    if (thumbnailLoading != null) return thumbnailLoading;
    if (currentlyLoadedImage == LODImageType.thumbnail) return;
    if (currentlyLoadedImage == LODImageType.fullres) return;

    thumbnailLoading = () async {
      var bytes = await loadThumbnail!.call();
      if (bytes == null) return;

      mimeType = Mime.lookupType("", data: bytes);

      var codec = await callback(
        await ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: (intrinsicWidth, intrinsicHeight) {
          return TargetImageSize(height: thumbnailHeight);
        },
      );

      await _setCodec(LODImageType.thumbnail, codec);
    }();

    await thumbnailLoading;
    thumbnailLoading = null;
  }

  Future<void> fetchFullRes() async {
    return _loadFullRes();
  }

  Future<void> fetchThumbnail() async {
    return _loadThumbnail();
  }

  Future<void> _loadFullRes() async {
    if (fullResLoading != null) {
      return fullResLoading;
    }

    if (currentlyLoadedImage == LODImageType.fullres) {
      return;
    }

    if (loadFullRes == null) {
      return;
    }

    fullResLoading = () async {
      var bytes = await loadFullRes!.call();
      if (bytes == null) return;

      mimeType = Mime.lookupType("", data: bytes);
      var codec = await callback(
        await ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: (intrinsicWidth, intrinsicHeight) {
          return TargetImageSize(height: fullResHeight);
        },
      );

      await _setCodec(LODImageType.fullres, codec);
    }();

    await fullResLoading;
    fullResLoading = null;
  }

  Future<void> _setCodec(LODImageType type, Codec codec) async {
    _codec = codec;
    await _decodeNextFrameAndSchedule();
    currentlyLoadedImage = type;
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    _nextFrame?.image.dispose();
    _nextFrame = null;

    _nextFrame = await _codec!.getNextFrame();

    _emitFrame(ImageInfo(
      image: _nextFrame!.image.clone(),
      scale: _scale,
      debugLabel: debugLabel,
    ));

    if (_codec!.frameCount == 1) {
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
    if (!hasListeners) return;
    setImage(imageInfo);
    _framesEmitted += 1;
  }
}
