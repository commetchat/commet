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

import 'package:flutter/foundation.dart' show kIsWeb;

import '../support/native.dart';
import '../support/platform.dart';
import '../track/local/audio.dart';
import '../track/local/video.dart';
import '../types/video_parameters.dart';
import 'processor.dart';
import 'processor_native.dart' if (dart.library.js_interop) 'processor_web.dart';

/// A type that represents front or back of the camera.
enum CameraPosition {
  front,
  back,
}

enum CameraFocusMode { auto, locked }

enum CameraExposureMode { auto, locked }

/// Convenience extension for [CameraPosition].
extension CameraPositionExt on CameraPosition {
  /// Return a [CameraPosition] which front and back is switched.
  CameraPosition switched() => {
        CameraPosition.front: CameraPosition.back,
        CameraPosition.back: CameraPosition.front,
      }[this]!;
}

/// Options used when creating a [LocalVideoTrack] that captures the camera.
class CameraCaptureOptions extends VideoCaptureOptions {
  final CameraPosition cameraPosition;

  /// set to false to only toggle enabled instead of stop/replaceTrack for muting
  final bool stopCameraCaptureOnMute;

  /// The focus mode to use for the camera.
  final CameraFocusMode focusMode;

  /// The exposure mode to use for the camera.
  final CameraExposureMode exposureMode;

  const CameraCaptureOptions({
    this.cameraPosition = CameraPosition.front,
    this.focusMode = CameraFocusMode.auto,
    this.exposureMode = CameraExposureMode.auto,
    String? deviceId,
    double? maxFrameRate,
    VideoParameters params = VideoParametersPresets.h720_169,
    this.stopCameraCaptureOnMute = true,
    TrackProcessor<VideoProcessorOptions>? processor,
  }) : super(
          params: params,
          deviceId: deviceId,
          maxFrameRate: maxFrameRate,
          processor: processor,
        );

  CameraCaptureOptions.from({required VideoCaptureOptions captureOptions})
      : cameraPosition = CameraPosition.front,
        focusMode = CameraFocusMode.auto,
        exposureMode = CameraExposureMode.auto,
        stopCameraCaptureOnMute = true,
        super(
          params: captureOptions.params,
          deviceId: captureOptions.deviceId,
          maxFrameRate: captureOptions.maxFrameRate,
          processor: captureOptions.processor,
        );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = <String, dynamic>{
      ...super.toMediaConstraintsMap(),
      if (deviceId == null) 'facingMode': cameraPosition == CameraPosition.front ? 'user' : 'environment'
    };
    if (deviceId != null && deviceId!.isNotEmpty) {
      if (kIsWeb) {
        if (isChrome129OrLater()) {
          constraints['deviceId'] = {'exact': deviceId};
        } else {
          constraints['deviceId'] = {'ideal': deviceId};
        }
      } else {
        constraints['optional'] = [
          {'sourceId': deviceId}
        ];
      }
    }
    if (maxFrameRate != null) {
      constraints['frameRate'] = {'max': maxFrameRate};
    }
    return constraints;
  }

  // Returns new options with updated properties
  CameraCaptureOptions copyWith({
    CameraPosition? cameraPosition,
    CameraFocusMode? focusMode,
    CameraExposureMode? exposureMode,
    String? deviceId,
    double? maxFrameRate,
    VideoParameters? params,
    bool? stopCameraCaptureOnMute,
    TrackProcessor<VideoProcessorOptions>? processor,
  }) =>
      CameraCaptureOptions(
        cameraPosition: cameraPosition ?? this.cameraPosition,
        focusMode: focusMode ?? this.focusMode,
        exposureMode: exposureMode ?? this.exposureMode,
        deviceId: deviceId ?? this.deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
        params: params ?? this.params,
        stopCameraCaptureOnMute: stopCameraCaptureOnMute ?? this.stopCameraCaptureOnMute,
        processor: processor ?? this.processor,
      );
}

/// Options used when creating a [LocalVideoTrack] that captures the screen.
class ScreenShareCaptureOptions extends VideoCaptureOptions {
  /// iOS only flag: Use Broadcast Extension for screen share capturing.
  /// See instructions on how to setup your Broadcast Extension here:
  /// https://github.com/flutter-webrtc/flutter-webrtc/wiki/iOS-Screen-Sharing#broadcast-extension-quick-setup
  final bool useiOSBroadcastExtension;

  // for browser only, if true, will capture screen audio.
  final bool captureScreenAudio;

  /// for browser only, if true, will capture current tab.
  final bool preferCurrentTab;

  /// for browser only, include or exclude self browser surface.
  final String? selfBrowserSurface;

  const ScreenShareCaptureOptions({
    this.useiOSBroadcastExtension = false,
    this.captureScreenAudio = false,
    this.preferCurrentTab = false,
    this.selfBrowserSurface,
    String? sourceId,
    double? maxFrameRate,
    VideoParameters params = VideoParametersPresets.screenShareH1080FPS15,
  }) : super(params: params, deviceId: sourceId, maxFrameRate: maxFrameRate);

  ScreenShareCaptureOptions.from(
      {this.useiOSBroadcastExtension = false,
      this.captureScreenAudio = false,
      this.preferCurrentTab = false,
      this.selfBrowserSurface,
      required VideoCaptureOptions captureOptions})
      : super(params: captureOptions.params);

  ScreenShareCaptureOptions copyWith({
    bool? useiOSBroadcastExtension,
    bool? captureScreenAudio,
    VideoParameters? params,
    String? sourceId,
    double? maxFrameRate,
    bool? preferCurrentTab,
    String? selfBrowserSurface,
  }) =>
      ScreenShareCaptureOptions(
        useiOSBroadcastExtension: useiOSBroadcastExtension ?? this.useiOSBroadcastExtension,
        captureScreenAudio: captureScreenAudio ?? this.captureScreenAudio,
        params: params ?? this.params,
        sourceId: sourceId ?? deviceId,
        maxFrameRate: maxFrameRate ?? this.maxFrameRate,
        preferCurrentTab: preferCurrentTab ?? this.preferCurrentTab,
        selfBrowserSurface: selfBrowserSurface ?? this.selfBrowserSurface,
      );

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = super.toMediaConstraintsMap();
    if (useiOSBroadcastExtension && lkPlatformIs(PlatformType.iOS)) {
      constraints['deviceId'] = 'broadcast-manual';
    }
    if (lkPlatformIsDesktop()) {
      if (deviceId != null) {
        constraints['deviceId'] = {'exact': deviceId};
      }
      if (maxFrameRate != 0.0) {
        constraints['mandatory'] = {'frameRate': maxFrameRate};
      }
    }
    return constraints;
  }
}

/// Base class for track options.
abstract class LocalTrackOptions {
  const LocalTrackOptions();

  // All subclasses must be able to report constraints
  Map<String, dynamic> toMediaConstraintsMap();
}

/// Base class for options when creating a [LocalVideoTrack].
abstract class VideoCaptureOptions extends LocalTrackOptions {
  // final LocalVideoTrackType type;
  final VideoParameters params;

  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// ```dart
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// // or
  /// List<DesktopCapturerSource> desktopSources = await rtc.desktopCapturer.getSources(types: [rtc.SourceType.Screen, rtc.SourceType.Window]);
  /// ```
  final String? deviceId;

  // Limit the maximum frameRate of the capture device.
  final double? maxFrameRate;

  /// A processor to apply to the video track.
  final TrackProcessor<VideoProcessorOptions>? processor;

  const VideoCaptureOptions({
    this.params = VideoParametersPresets.h540_169,
    this.deviceId,
    this.maxFrameRate,
    this.processor,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() => params.toMediaConstraintsMap();
}

/// Options used when creating a [LocalAudioTrack].
class AudioCaptureOptions extends LocalTrackOptions {
  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// ```
  /// import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// ```
  final String? deviceId;

  /// Attempt to use noiseSuppression option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/noiseSuppression
  /// Defaults to true.
  final bool noiseSuppression;

  /// Attempt to use echoCancellation option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/echoCancellation
  /// Defaults to true.
  final bool echoCancellation;

  /// Attempt to use autoGainControl option (if supported by the platform)
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints/autoGainControl
  /// Defaults to true.
  final bool autoGainControl;

  /// Attempt to use highPassFilter options (if supported by the platform)
  /// Defaults to false.
  final bool highPassFilter;

  /// Attempt to use typingNoiseDetection option (if supported by the platform)
  /// Defaults to true.
  final bool typingNoiseDetection;

  /// Attempt to use voiceIsolation option (if supported by the platform)
  /// Defaults to true.
  final bool voiceIsolation;

  /// set to false to only toggle enabled instead of stop/replaceTrack for muting
  final bool stopAudioCaptureOnMute;

  /// A processor to apply to the audio track.
  final TrackProcessor<AudioProcessorOptions>? processor;

  const AudioCaptureOptions({
    this.deviceId,
    this.noiseSuppression = true,
    this.echoCancellation = true,
    this.autoGainControl = true,
    this.highPassFilter = false,
    this.voiceIsolation = true,
    this.typingNoiseDetection = true,
    this.stopAudioCaptureOnMute = true,
    this.processor,
  });

  @override
  Map<String, dynamic> toMediaConstraintsMap() {
    final constraints = <String, dynamic>{};

    if (Native.bypassVoiceProcessing) {
      constraints['optional'] = <Map<String, dynamic>>[
        <String, dynamic>{'googEchoCancellation': false},
        <String, dynamic>{'googEchoCancellation2': false},
        <String, dynamic>{'googNoiseSuppression': false},
        <String, dynamic>{'googNoiseSuppression2': false},
        <String, dynamic>{'googAutoGainControl': false},
        <String, dynamic>{'googHighpassFilter': false},
        <String, dynamic>{'googTypingNoiseDetection': false},
        <String, dynamic>{'noiseSuppression': false},
        <String, dynamic>{'echoCancellation': false},
        <String, dynamic>{'autoGainControl': false},
        <String, dynamic>{'voiceIsolation': false},
        <String, dynamic>{'googDAEchoCancellation': false},
      ];
    } else {
      /// in we platform it's not possible to provide optional and mandatory parameters.
      /// deviceId is a mandatory parameter
      if (!kIsWeb || (kIsWeb && deviceId == null)) {
        constraints['optional'] = <Map<String, dynamic>>[
          <String, dynamic>{'echoCancellation': echoCancellation},
          <String, dynamic>{'noiseSuppression': noiseSuppression},
          <String, dynamic>{'autoGainControl': autoGainControl},
          <String, dynamic>{'voiceIsolation': noiseSuppression},
          <String, dynamic>{'googDAEchoCancellation': echoCancellation},
          <String, dynamic>{'googEchoCancellation': echoCancellation},
          <String, dynamic>{'googEchoCancellation2': echoCancellation},
          <String, dynamic>{'googNoiseSuppression': noiseSuppression},
          <String, dynamic>{'googNoiseSuppression2': noiseSuppression},
          <String, dynamic>{'googAutoGainControl': autoGainControl},
          <String, dynamic>{'googHighpassFilter': highPassFilter},
          <String, dynamic>{'googTypingNoiseDetection': typingNoiseDetection},
        ];
      }
    }

    if (deviceId != null && deviceId!.isNotEmpty) {
      if (kIsWeb) {
        if (isChrome129OrLater()) {
          constraints['deviceId'] = {'exact': deviceId};
        } else {
          constraints['deviceId'] = {'ideal': deviceId};
        }
      } else {
        constraints['optional'].cast<Map<String, dynamic>>().add(<String, dynamic>{'sourceId': deviceId});
      }
    }
    return constraints;
  }

  AudioCaptureOptions copyWith({
    String? deviceId,
    bool? noiseSuppression,
    bool? echoCancellation,
    bool? autoGainControl,
    bool? highPassFilter,
    bool? typingNoiseDetection,
  }) {
    return AudioCaptureOptions(
      deviceId: deviceId ?? this.deviceId,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      autoGainControl: autoGainControl ?? this.autoGainControl,
      highPassFilter: highPassFilter ?? this.highPassFilter,
      typingNoiseDetection: typingNoiseDetection ?? this.typingNoiseDetection,
    );
  }
}

class AudioOutputOptions {
  /// The deviceId of the output device to use.
  final String? deviceId;

  /// If true, the audio will be played on the speaker.
  /// for mobile only
  final bool? speakerOn;

  const AudioOutputOptions({this.deviceId, this.speakerOn});

  AudioOutputOptions copyWith({String? deviceId, bool? speakerOn}) {
    return AudioOutputOptions(
      deviceId: deviceId ?? this.deviceId,
      speakerOn: speakerOn ?? this.speakerOn,
    );
  }
}
