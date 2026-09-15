// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../events.dart';
import '../extensions.dart';
import '../internal/events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../support/platform.dart';
import '../track/local/local.dart';
import '../track/local/video.dart';
import '../track/options.dart';
import '../types/other.dart';

enum VideoViewMirrorMode {
  auto,
  off,
  mirror,
}

enum VideoRenderMode {
  auto,
  texture,
  platformView,
}

enum VideoViewFit {
  contain,
  cover,
}

extension VideoViewFitExt on VideoViewFit {
  rtc.RTCVideoViewObjectFit toRTCType() {
    if (this == VideoViewFit.cover) {
      return rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
    return rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }
}

/// Widget that renders a [VideoTrack].
class VideoTrackRenderer extends StatefulWidget {
  final VideoTrack track;
  final VideoViewFit fit;
  final VideoViewMirrorMode mirrorMode;
  final VideoRenderMode renderMode;
  final rtc.RTCVideoRenderer? cachedRenderer;
  final bool autoDisposeRenderer;

  /// wrap the video view in a Center widget (if [fit] is [VideoViewFit.contain])
  final bool autoCenter;

  const VideoTrackRenderer(
    this.track, {
    this.fit = VideoViewFit.contain,
    this.mirrorMode = VideoViewMirrorMode.auto,
    this.renderMode = VideoRenderMode.texture,
    this.autoDisposeRenderer = true,
    this.cachedRenderer,
    this.autoCenter = true,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTrackRendererState();
}

class _VideoTrackRendererState extends State<VideoTrackRenderer> {
  rtc.VideoRenderer? _renderer;
  // for flutter web only.
  bool _rendererReadyForWeb = false;
  double? _aspectRatio;
  EventsListener<TrackEvent>? _listener;
  // Used to compute visibility information
  late GlobalKey _internalKey;

  Future<rtc.VideoRenderer> _initializeRenderer() async {
    if (lkPlatformIs(PlatformType.iOS) && widget.renderMode == VideoRenderMode.platformView) {
      return Null as Future<rtc.VideoRenderer>;
    }
    if (_renderer == null) {
      _renderer = rtc.RTCVideoRenderer();
      await _renderer!.initialize();
    }
    await _attach();
    return _renderer!;
  }

  void setZoom(double zoomLevel) async {
    final videoTrack = _renderer?.srcObject!.getVideoTracks().first;
    if (videoTrack == null) return;
    await rtc.Helper.setZoom(videoTrack, zoomLevel);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final videoTrack = _renderer?.srcObject!.getVideoTracks().first;
    if (videoTrack == null) return;

    final point = Point<double>(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    // Don't wait here as it will slow down the UI unnecessarily.
    unawaited(rtc.Helper.setFocusPoint(videoTrack, point));
    unawaited(rtc.Helper.setExposurePoint(videoTrack, point));
  }

  void disposeRenderer() {
    try {
      _renderer?.onResize = null;
      _renderer?.srcObject = null;
      unawaited(_renderer?.dispose());
      _renderer = null;
    } catch (e) {
      logger.warning('Got error disposing renderer: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.cachedRenderer != null) {
      _renderer = widget.cachedRenderer;
    }
    _internalKey = widget.track.addViewKey();
    if (kIsWeb) {
      unawaited(() async {
        await _initializeRenderer();
        if (!mounted) return;
        setState(() => _rendererReadyForWeb = true);
      }());
    }
  }

  @override
  void dispose() {
    widget.track.removeViewKey(_internalKey);
    unawaited(_listener?.dispose());
    if (widget.autoDisposeRenderer) {
      disposeRenderer();
    }
    super.dispose();
  }

  Future<void> _attach() async {
    _renderer?.srcObject = widget.track.mediaStream;
    await _listener?.dispose();
    _listener = widget.track.createListener()
      ..on<TrackStreamUpdatedEvent>((event) {
        if (!mounted) return;
        _renderer?.srcObject = event.stream;
      })
      ..on<LocalTrackOptionsUpdatedEvent>((event) {
        if (!mounted) return;
        // force recompute of mirror mode
        setState(() {});
      });
    _renderer?.onResize = () {
      if (mounted) {
        setState(() {
          _aspectRatio = (_renderer as rtc.RTCVideoRenderer?)?.videoValue.aspectRatio;
        });
      }
    };
  }

  @override
  void didUpdateWidget(covariant VideoTrackRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track != oldWidget.track) {
      oldWidget.track.removeViewKey(_internalKey);
      _internalKey = widget.track.addViewKey();
      unawaited(() async {
        await _attach();
      }());
    }

    if ([BrowserType.safari, BrowserType.firefox].contains(lkBrowser()) && oldWidget.key != widget.key) {
      _renderer?.srcObject = widget.track.mediaStream;
    }
  }

  Widget _videoViewForWeb() => !_rendererReadyForWeb
      ? Container()
      : Builder(
          key: _internalKey,
          builder: (ctx) {
            // let it render before notifying build
            WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
              widget.track.onVideoViewBuild?.call(_internalKey);
            });
            return rtc.RTCVideoView(
              _renderer! as rtc.RTCVideoRenderer,
              mirror: _shouldMirror(),
              filterQuality: FilterQuality.medium,
              objectFit: widget.fit.toRTCType(),
            );
          },
        );

  Widget _videoRendererView() {
    if (lkPlatformIs(PlatformType.iOS) && widget.renderMode == VideoRenderMode.platformView) {
      return rtc.RTCVideoPlatFormView(
        mirror: _shouldMirror(),
        objectFit: widget.fit.toRTCType(),
        onViewReady: (controller) async {
          _renderer = controller;
          _renderer?.srcObject = widget.track.mediaStream;
          await _attach();
        },
      );
    }
    return rtc.RTCVideoView(
      _renderer! as rtc.RTCVideoRenderer,
      mirror: _shouldMirror(),
      filterQuality: FilterQuality.medium,
      objectFit: widget.fit.toRTCType(),
    );
  }

  Widget _videoViewForNative() => FutureBuilder(
      future: _initializeRenderer(),
      builder: (context, snapshot) {
        if ((snapshot.hasData && _renderer != null) ||
            (lkPlatformIs(PlatformType.iOS) && widget.renderMode == VideoRenderMode.platformView)) {
          return Builder(
            key: _internalKey,
            builder: (ctx) {
              // let it render before notifying build
              WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
                widget.track.onVideoViewBuild?.call(_internalKey);
              });

              if (!lkPlatformIsMobile() || widget.track is! LocalVideoTrack) {
                return _videoRendererView();
              }
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return GestureDetector(
                    onScaleStart: (details) {},
                    onScaleUpdate: (details) {
                      if (details.scale != 1.0) {
                        setZoom(details.scale);
                      }
                    },
                    onTapDown: (TapDownDetails details) => onViewFinderTap(details, constraints),
                    child: _videoRendererView(),
                  );
                },
              );
            },
          );
        }
        return Container();
      });

  // FutureBuilder will cause flickering for flutter web. so using
  // different rendering methods for web and native.
  @override
  Widget build(BuildContext context) {
    final child = kIsWeb ? _videoViewForWeb() : _videoViewForNative();

    if (widget.fit == VideoViewFit.cover) {
      return child;
    }

    final videoView = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
          return child;
        }
        if (_aspectRatio == null) {
          return child;
        }

        bool fixHeight;
        if (!constraints.hasBoundedWidth) {
          fixHeight = true;
        } else if (!constraints.hasBoundedHeight) {
          fixHeight = false;
        } else {
          // both width and height are bound, figure out which to fix based on aspect ratios
          final constraintsAspectRatio = constraints.maxWidth / constraints.maxHeight;
          fixHeight = constraintsAspectRatio > _aspectRatio!;
        }
        final double width;
        final double height;
        if (fixHeight) {
          height = constraints.maxHeight;
          width = height * _aspectRatio!;
        } else {
          width = constraints.maxWidth;
          height = width / _aspectRatio!;
        }
        return SizedBox(width: width, height: height, child: child);
      },
    );

    if (widget.autoCenter) {
      return Center(child: videoView);
    } else {
      return videoView;
    }
  }

  bool _shouldMirror() {
    // off for screen share
    if (widget.track.source == TrackSource.screenShareVideo) return false;
    // on
    if (widget.mirrorMode == VideoViewMirrorMode.mirror) return true;
    // auto
    if (widget.mirrorMode == VideoViewMirrorMode.auto) {
      final track = widget.track;
      if (track is LocalVideoTrack) {
        final settings = track.mediaStreamTrack.getSettings();
        final facingMode = settings['facingMode'];
        if (facingMode != null) {
          return facingMode == 'user';
        }
        final options = track.currentOptions;
        if (options is CameraCaptureOptions) {
          // mirror if front camera
          return options.cameraPosition == CameraPosition.front;
        }
      }
    }
    // default to false
    return false;
  }
}
