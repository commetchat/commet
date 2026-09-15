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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../audio/audio_frame_capture.dart';
import '../../events.dart';
import '../../exceptions.dart';
import '../../extensions.dart';
import '../../internal/events.dart';
import '../../logger.dart';
import '../../participant/remote.dart';
import '../../support/platform.dart';
import '../../types/other.dart';
import '../options.dart';
import '../processor.dart';
import '../processor_native.dart' if (dart.library.js_interop) '../processor_web.dart';
import '../remote/audio.dart';
import '../remote/video.dart';
import '../track.dart';
import 'audio.dart';
import 'video.dart';

/// Used to group [LocalVideoTrack] and [RemoteVideoTrack].
mixin VideoTrack on Track {
  @internal
  final List<GlobalKey> viewKeys = [];

  @internal
  Function(Key)? onVideoViewBuild;

  @internal
  GlobalKey addViewKey() {
    final key = GlobalKey();
    viewKeys.add(key);
    return key;
  }

  @internal
  void removeViewKey(GlobalKey key) {
    viewKeys.remove(key);
  }
}

/// Used to group [LocalAudioTrack] and [RemoteAudioTrack].
mixin AudioTrack on Track {
  final Map<AudioRendererOptions, _AudioCaptureGroup> _captureGroups = {};

  /// Register a callback to receive raw PCM audio frames from this track.
  ///
  /// Multiple renderers with different [options] each get their own capture
  /// pipeline. Renderers sharing the same options share a single capture.
  ///
  /// Returns a function that, when called, removes this renderer.
  /// When the last renderer for a given options config is removed, that
  /// capture stops automatically.
  CancelListenFunc addAudioRenderer({
    required AudioFrameCallback onFrame,
    AudioRendererOptions options = const AudioRendererOptions(),
  }) {
    final group = _captureGroups.putIfAbsent(
      options,
      () => _AudioCaptureGroup(track: mediaStreamTrack, options: options),
    );
    group.renderers.add(onFrame);

    return () async {
      group.renderers.remove(onFrame);
      if (group.renderers.isEmpty) {
        _captureGroups.remove(options);
        await group.stop();
      }
    };
  }

  @override
  Future<void> onStarted() async {
    logger.fine('AudioTrack.onStarted()');
  }

  @override
  Future<void> onStopped() async {
    logger.fine('AudioTrack.onStopped()');
    for (final group in _captureGroups.values) {
      await group.stop();
    }
    _captureGroups.clear();
  }
}

class _AudioCaptureGroup {
  final List<AudioFrameCallback> renderers = [];
  late final Future<void> _startFuture;
  AudioFrameCapture? _capture;
  StreamSubscription? _subscription;

  _AudioCaptureGroup({
    required rtc.MediaStreamTrack track,
    required AudioRendererOptions options,
  }) {
    _startFuture = _start(track, options);
  }

  Future<void> _start(rtc.MediaStreamTrack track, AudioRendererOptions options) async {
    final capture = createAudioFrameCapture();
    _capture = capture;

    final result = await capture.start(
      track: track,
      rendererId: Track.uuid.v4(),
      sampleRate: options.sampleRate,
      channels: options.channels,
      format: options.format,
    );

    if (!result) {
      logger.warning('Failed to start audio capture for renderer');
      return;
    }

    _subscription = capture.frameStream.listen((frame) {
      for (final renderer in List.of(renderers)) {
        renderer(frame);
      }
    });
  }

  Future<void> stop() async {
    await _startFuture;
    await _subscription?.cancel();
    _subscription = null;
    await _capture?.stop();
    _capture = null;
  }
}

/// Base class for [LocalAudioTrack] and [LocalVideoTrack].
abstract class LocalTrack extends Track {
  /// Options used for this track
  abstract LocalTrackOptions currentOptions;

  bool _published = false;
  bool get isPublished => _published;

  String? codec;

  bool _stopped = false;

  TrackProcessor? _processor;

  TrackProcessor? get processor => _processor;

  LocalTrack(TrackType kind, TrackSource source, rtc.MediaStream mediaStream, rtc.MediaStreamTrack mediaStreamTrack)
      : super(
          kind,
          source,
          mediaStream,
          mediaStreamTrack,
        ) {
    mediaStreamTrack.onEnded = () {
      logger.fine('MediaStreamTrack.onEnded()');
      events.emit(TrackEndedEvent(track: this));
    };
  }

  /// Mutes this [LocalTrack]. This will stop the sending of track data
  /// and notify the [RemoteParticipant] with [TrackMutedEvent].
  /// Returns true if muted, false if unchanged.
  Future<bool> mute({bool stopOnMute = true}) async {
    logger.fine('LocalTrack.mute() muted: $muted');
    if (muted) return false; // already muted
    await disable();
    if (!skipStopForTrackMute() && stopOnMute) {
      await stop();
    }
    updateMuted(true, shouldSendSignal: true);
    return true;
  }

  /// Un-mutes this [LocalTrack]. This will re-start the sending of track data
  /// and notify the [RemoteParticipant] with [TrackUnmutedEvent].
  /// Returns true if un-muted, false if unchanged.
  Future<bool> unmute({bool stopOnMute = true}) async {
    logger.fine('LocalTrack.unmute() muted: $muted');
    if (!muted) return false; // already un-muted
    if (!skipStopForTrackMute() && stopOnMute) {
      await restartTrack();
    }
    await enable();
    updateMuted(false, shouldSendSignal: true);
    return true;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop() || !_stopped;
    if (didStop) {
      logger.fine('Stopping mediaStreamTrack...');
      try {
        await mediaStreamTrack.stop();
      } catch (error) {
        logger.severe('MediaStreamTrack.stop() did throw $error');
      }
      try {
        await mediaStream.dispose();
      } catch (error) {
        logger.severe('MediaStreamTrack.dispose() did throw $error');
      }
      _stopped = true;
      try {
        if (_processor != null) {
          await stopProcessor();
        }
      } catch (error) {
        logger.severe('LocalTrack.stopProcessor did throw: $error');
      }
    }
    return didStop;
  }

  /// Creates a [rtc.MediaStream] from [LocalTrackOptions].
  @internal
  static Future<rtc.MediaStream> createStream(
    LocalTrackOptions options,
  ) async {
    final constraints = <String, dynamic>{
      'audio': options is AudioCaptureOptions
          ? options.toMediaConstraintsMap()
          : options is ScreenShareCaptureOptions
              ? (options).captureScreenAudio
              : false,
      'video': options is VideoCaptureOptions ? options.toMediaConstraintsMap() : false,
    };

    final rtc.MediaStream stream;
    if (options is ScreenShareCaptureOptions) {
      if (kIsWeb) {
        if (options.preferCurrentTab) {
          constraints['preferCurrentTab'] = true;
        }
        if (options.selfBrowserSurface != null) {
          constraints['selfBrowserSurface'] = options.selfBrowserSurface!;
        }

        // Remove resolution settings to fix low-resolution screen share on Safari 17.
        // related bug: https://bugs.webkit.org/show_bug.cgi?id=263015
        if (lkBrowser() == BrowserType.safari && lkBrowserVersion().major == 17) {
          constraints['video'] = true;
        }
      }
      stream = await rtc.navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      // options is CameraVideoTrackOptions
      stream = await rtc.navigator.mediaDevices.getUserMedia(constraints);
    }

    // Check if the stream looks good
    if ((options is VideoCaptureOptions && stream.getVideoTracks().isEmpty) ||
        (options is AudioCaptureOptions && stream.getAudioTracks().isEmpty)) {
      throw TrackCreateException('Failed to create stream, at least 1 video or audio track should exist');
    }
    return stream;
  }

  /// Restarts the track with new options. This is useful when switching between
  /// front and back cameras.
  Future<void> restartTrack([
    LocalTrackOptions? options,
  ]) async {
    if (sender == null) throw TrackCreateException('could not restart track');
    if (options != null && currentOptions.runtimeType != options.runtimeType) {
      throw Exception('options must be a ${currentOptions.runtimeType}');
    }

    currentOptions = options ?? currentOptions;

    // stop if not already stopped...
    await stop();

    // create new track with options
    final newStream = await LocalTrack.createStream(currentOptions);
    final newTrack = newStream.getTracks().first;

    final processor = _processor;

    await stopProcessor();

    // replace track on sender
    try {
      await sender?.replaceTrack(newTrack);
      if (this is LocalVideoTrack) {
        final videoTrack = this as LocalVideoTrack;
        await videoTrack.replaceTrackForMultiCodecSimulcast(newTrack);
      }
    } catch (error) {
      logger.severe('RTCRtpSender.replaceTrack() did throw $error');
    }

    // set new stream & track to this object
    updateMediaStreamAndTrack(newStream, newTrack);

    if (processor != null) {
      await setProcessor(processor);
    }

    // mark as started
    await start();

    // notify so VideoView can re-compute mirror mode if necessary
    events.emit(LocalTrackOptionsUpdatedEvent(
      track: this,
      options: currentOptions,
    ));
  }

  Future<void> setProcessor(TrackProcessor? processor) async {
    if (processor == null) {
      return;
    }

    if (_processor != null) {
      await stopProcessor();
    }

    _processor = processor;

    final processorOptions = kind == TrackType.VIDEO
        ? VideoProcessorOptions(track: mediaStreamTrack)
        : AudioProcessorOptions(track: mediaStreamTrack);

    await _processor!.init(processorOptions);

    if (_processor?.processedTrack != null) {
      setProcessedTrack(processor.processedTrack!);
      // COMMET: if this track is already on a sender (processor set after
      // publish, or restartTrack re-applying it after a device switch), the
      // sender still holds the raw track. Swap it, otherwise unprocessed
      // audio keeps going out.
      if (sender != null) {
        try {
          await sender!.replaceTrack(processor.processedTrack!);
        } catch (error) {
          logger.severe('replaceTrack(processedTrack) did throw $error');
        }
      }
    }

    logger.fine('processor initialized');

    events.emit(TrackProcessorUpdateEvent(track: this, processor: _processor));
  }

  @internal
  Future<void> stopProcessor({bool keepElement = false}) async {
    if (_processor == null) return;

    logger.fine('stopping processor');
    // COMMET: put the original capture track back on the sender before the
    // processor tears its graph down, so audio keeps flowing unprocessed.
    if (originalTrack != null) {
      final original = originalTrack!;
      restoreOriginalTrack();
      if (sender != null) {
        try {
          await sender!.replaceTrack(original);
        } catch (error) {
          logger.severe('replaceTrack(originalTrack) did throw $error');
        }
      }
    }
    await _processor?.destroy();
    _processor = null;

    if (!keepElement) {
      // processorElement?.remove();
      // processorElement = null;
    }

    // apply original track constraints in case the processor changed them
    //await this._mediaStreamTrack.applyConstraints(this._constraints);
    // force re-setting of the mediaStreamTrack on the sender
    //await this.setMediaStreamTrack(this._mediaStreamTrack, true);

    events.emit(TrackProcessorUpdateEvent(track: this));
  }

  @internal
  @mustCallSuper
  Future<bool> onPublish() async {
    if (_published) {
      // already published
      return false;
    }

    logger.fine('$objectId.publish()');
    _published = true;
    return true;
  }

  @internal
  @mustCallSuper
  Future<bool> onUnpublish() async {
    if (!_published) {
      // already unpublished
      return false;
    }

    logger.fine('$objectId.unpublish()');
    _published = false;
    return true;
  }
}
