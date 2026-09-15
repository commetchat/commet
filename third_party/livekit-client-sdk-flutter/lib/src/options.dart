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

import 'constants.dart';
import 'e2ee/options.dart';
import 'track/local/audio.dart';
import 'track/local/video.dart';
import 'track/options.dart';
import 'types/audio_encoding.dart';
import 'types/other.dart';
import 'types/video_encoding.dart';
import 'types/video_parameters.dart';
import 'utils.dart';

class TrackOption<E extends Object, T extends Object> {
  final E? enabled;
  final T? track;
  const TrackOption({this.enabled, this.track});
}

/// This will enable the local participant to publish tracks on connect,
/// instead of having to explicitly publish them.
/// Defaults to false for all three tracks: microphone, camera, and screen.
/// You can also create LocalAudio/VideoTrack on your `PreJoin` page
/// (preview camera or select audio device), Automatically publish these
/// tracks after the room is connected.
class FastConnectOptions {
  FastConnectOptions({
    this.microphone = const TrackOption(enabled: false),
    this.camera = const TrackOption(enabled: false),
    this.screen = const TrackOption(enabled: false),
  });
  final TrackOption<bool, LocalAudioTrack> microphone;
  final TrackOption<bool, LocalVideoTrack> camera;
  final TrackOption<bool, LocalVideoTrack> screen;
}

/// Options used when connecting to the server.
class ConnectOptions {
  /// Auto-subscribe to existing and new [RemoteTrackPublication]s after
  /// successfully connecting to the [Room].
  /// Defaults to true.
  final bool autoSubscribe;

  /// The default [RTCConfiguration] to be used.
  final RTCConfiguration rtcConfiguration;

  /// The protocol version to be used. Usually this doesn't need to be modified.
  final ProtocolVersion protocolVersion;

  final Timeouts timeouts;

  const ConnectOptions({
    this.autoSubscribe = true,
    this.rtcConfiguration = const RTCConfiguration(),
    this.protocolVersion = ProtocolVersion.v16,
    this.timeouts = Timeouts.defaultTimeouts,
  });
}

/// Options used to modify the behavior of the [Room].
/// {@category Room}
class RoomOptions {
  /// Default options used for [LocalVideoTrack.createCameraTrack].
  final CameraCaptureOptions defaultCameraCaptureOptions;

  /// Default options used for [LocalVideoTrack.createScreenShareTrack].
  final ScreenShareCaptureOptions defaultScreenShareCaptureOptions;

  /// Default options used when capturing video for a [LocalAudioTrack].
  final AudioCaptureOptions defaultAudioCaptureOptions;

  /// Default options used when publishing a [LocalVideoTrack].
  final VideoPublishOptions defaultVideoPublishOptions;

  /// Default options used when publishing a [LocalAudioTrack].
  final AudioPublishOptions defaultAudioPublishOptions;

  final AudioOutputOptions defaultAudioOutputOptions;

  /// AdaptiveStream lets LiveKit automatically manage quality of subscribed
  /// video tracks to optimize for bandwidth and CPU.
  /// When attached video elements are visible, it'll choose an appropriate
  /// resolution based on the size of largest video element it's attached to.
  ///
  /// When none of the video elements are visible, it'll temporarily pause
  /// the data flow until they are visible again.
  final bool adaptiveStream;

  /// enable Dynacast, off by default. With Dynacast dynamically pauses
  /// video layers that are not being consumed by any subscribers, significantly
  /// reducing publishing CPU and bandwidth usage.
  /// Dynacast will be enabled if SVC codecs (VP9/AV1) are used. Multi-codec
  /// simulcast requires dynacast
  final bool dynacast;

  /// Set this to false in case you would like to stop the track yourself.
  /// If you set this to false, make sure you call [Track.stop].
  /// Defaults to true.
  final bool stopLocalTrackOnUnpublish;

  /// Options for end-to-end encryption.
  @Deprecated('Use encryption instead')
  final E2EEOptions? e2eeOptions;

  /// @experimental
  /// Options for end-to-end encryption.
  final E2EEOptions? encryption;

  /// fast track publication
  final bool fastPublish;

  /// deprecated, use [createVisualizer] instead
  /// please refer to example/lib/widgets/sound_waveform.dart
  @Deprecated('Use createVisualizer instead')
  final bool? enableVisualizer;

  const RoomOptions({
    this.defaultCameraCaptureOptions = const CameraCaptureOptions(),
    this.defaultScreenShareCaptureOptions = const ScreenShareCaptureOptions(),
    this.defaultAudioCaptureOptions = const AudioCaptureOptions(),
    this.defaultVideoPublishOptions = const VideoPublishOptions(),
    this.defaultAudioPublishOptions = const AudioPublishOptions(),
    this.defaultAudioOutputOptions = const AudioOutputOptions(),
    this.adaptiveStream = false,
    this.dynacast = false,
    this.stopLocalTrackOnUnpublish = true,
    this.e2eeOptions,
    this.encryption,
    this.enableVisualizer = false,
    this.fastPublish = true,
  });

  RoomOptions copyWith({
    CameraCaptureOptions? defaultCameraCaptureOptions,
    ScreenShareCaptureOptions? defaultScreenShareCaptureOptions,
    AudioCaptureOptions? defaultAudioCaptureOptions,
    VideoPublishOptions? defaultVideoPublishOptions,
    AudioPublishOptions? defaultAudioPublishOptions,
    AudioOutputOptions? defaultAudioOutputOptions,
    bool? adaptiveStream,
    bool? dynacast,
    bool? stopLocalTrackOnUnpublish,
    E2EEOptions? e2eeOptions,
    E2EEOptions? encryption,
    bool? fastPublish,
  }) {
    return RoomOptions(
      defaultCameraCaptureOptions: defaultCameraCaptureOptions ?? this.defaultCameraCaptureOptions,
      defaultScreenShareCaptureOptions: defaultScreenShareCaptureOptions ?? this.defaultScreenShareCaptureOptions,
      defaultAudioCaptureOptions: defaultAudioCaptureOptions ?? this.defaultAudioCaptureOptions,
      defaultVideoPublishOptions: defaultVideoPublishOptions ?? this.defaultVideoPublishOptions,
      defaultAudioPublishOptions: defaultAudioPublishOptions ?? this.defaultAudioPublishOptions,
      defaultAudioOutputOptions: defaultAudioOutputOptions ?? this.defaultAudioOutputOptions,
      adaptiveStream: adaptiveStream ?? this.adaptiveStream,
      dynacast: dynacast ?? this.dynacast,
      stopLocalTrackOnUnpublish: stopLocalTrackOnUnpublish ?? this.stopLocalTrackOnUnpublish,
      // ignore: deprecated_member_use_from_same_package
      e2eeOptions: e2eeOptions ?? this.e2eeOptions,
      encryption: encryption ?? this.encryption,
      fastPublish: fastPublish ?? this.fastPublish,
    );
  }
}

enum DegradationPreference {
  @Deprecated('DISABLED is Deprecated for DegradationPreference')
  disabled,
  maintainFramerate,
  maintainResolution,
  balanced,
  maintainFramerateAndResolution,
}

class BackupVideoCodec {
  const BackupVideoCodec({
    this.enabled = true,
    this.codec = defaultVideoCodec,
    this.encoding,
    this.simulcast = true,
  });
  final bool enabled;
  final String codec;
  // optional, when unset, it'll be computed based on dimensions and codec
  final VideoEncoding? encoding;
  final bool simulcast;
  BackupVideoCodec copyWith({
    bool? enabled,
    String? codec,
    VideoEncoding? encoding,
    bool? simulcast,
  }) {
    return BackupVideoCodec(
      enabled: enabled ?? this.enabled,
      codec: codec ?? this.codec,
      encoding: encoding ?? this.encoding,
      simulcast: simulcast ?? this.simulcast,
    );
  }
}

class PublishOptions {
  /// Name of the track.
  final String? name;

  ///  Set stream name for the track. Audio and video tracks with the same stream name
  ///  will be placed in the same `MediaStream` and offer better synchronization.
  ///  By default, camera and microphone will be placed in a stream; as would screen_share and screen_share_audio
  final String? stream;

  const PublishOptions({
    this.name,
    this.stream,
  });
}

/// Options used when publishing video.
class VideoPublishOptions extends PublishOptions {
  static const defaultCameraName = 'camera';
  static const defaultScreenShareName = 'screenshare';
  static const defualtBackupVideoCodec = BackupVideoCodec(
    enabled: true,
    codec: defaultVideoCodec,
    simulcast: true,
  );

  /// The video codec to use.
  final String videoCodec;

  /// If provided, this will be used instead of the SDK's suggested encodings.
  /// Usually you don't need to provide this.
  /// Defaults to null.
  final VideoEncoding? videoEncoding;

  final VideoEncoding? screenShareEncoding;

  /// Whether to enable simulcast or not.
  /// https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb
  /// Defaults to true.
  final bool simulcast;

  final DegradationPreference? degradationPreference;

  final List<VideoParameters> videoSimulcastLayers;

  final List<VideoParameters> screenShareSimulcastLayers;

  final String? scalabilityMode;

  final BackupVideoCodec backupVideoCodec;

  const VideoPublishOptions(
      {super.name,
      super.stream,
      this.videoCodec = defaultVideoCodec,
      this.videoEncoding,
      this.screenShareEncoding,
      this.simulcast = true,
      this.videoSimulcastLayers = const [],
      this.screenShareSimulcastLayers = const [],
      this.backupVideoCodec = defualtBackupVideoCodec,
      this.scalabilityMode,
      this.degradationPreference});

  VideoPublishOptions copyWith({
    VideoEncoding? videoEncoding,
    VideoEncoding? screenShareEncoding,
    bool? simulcast,
    List<VideoParameters>? videoSimulcastLayers,
    List<VideoParameters>? screenShareSimulcastLayers,
    String? videoCodec,
    BackupVideoCodec? backupVideoCodec,
    DegradationPreference? degradationPreference,
    String? scalabilityMode,
    String? name,
    String? stream,
  }) =>
      VideoPublishOptions(
        videoEncoding: videoEncoding ?? this.videoEncoding,
        screenShareEncoding: screenShareEncoding ?? this.screenShareEncoding,
        simulcast: simulcast ?? this.simulcast,
        videoSimulcastLayers: videoSimulcastLayers ?? this.videoSimulcastLayers,
        screenShareSimulcastLayers: screenShareSimulcastLayers ?? this.screenShareSimulcastLayers,
        videoCodec: videoCodec ?? this.videoCodec,
        backupVideoCodec: backupVideoCodec ?? this.backupVideoCodec,
        degradationPreference: degradationPreference ?? this.degradationPreference,
        scalabilityMode: scalabilityMode ?? this.scalabilityMode,
        name: name ?? this.name,
        stream: stream ?? this.stream,
      );

  @override
  String toString() => '${runtimeType}(videoEncoding: ${videoEncoding}, simulcast: ${simulcast})';
}

/// Options used when publishing audio.
class AudioPublishOptions extends PublishOptions {
  static const defaultMicrophoneName = 'microphone';

  /// Preferred encoding parameters.
  /// Defaults to [AudioEncoding.presetMusic] when not set.
  final AudioEncoding? encoding;

  /// Whether to enable DTX (Discontinuous Transmission) or not.
  /// https://en.wikipedia.org/wiki/Discontinuous_transmission
  /// Defaults to true.
  final bool dtx;

  /// red (Redundant Audio Data)
  final bool? red;

  /// Mark this audio as originating from a pre-connect buffer.
  /// Used to populate protobuf audioFeatures (TF_PRECONNECT_BUFFER).
  final bool preConnect;

  const AudioPublishOptions({
    super.name,
    super.stream,
    this.encoding,
    this.dtx = true,
    this.red = true,
    this.preConnect = false,
  });

  AudioPublishOptions copyWith({
    AudioEncoding? encoding,
    bool? dtx,
    String? name,
    String? stream,
    bool? red,
    bool? preConnect,
  }) =>
      AudioPublishOptions(
        encoding: encoding ?? this.encoding,
        dtx: dtx ?? this.dtx,
        name: name ?? this.name,
        stream: stream ?? this.stream,
        red: red ?? this.red,
        preConnect: preConnect ?? this.preConnect,
      );

  @override
  String toString() => '${runtimeType}(encoding: ${encoding}, dtx: ${dtx}, red: ${red}, preConnect: ${preConnect})';
}

final backupCodecs = ['vp8', 'h264'];

final videoCodecs = ['vp8', 'h264', 'h265', 'vp9', 'av1'];

bool isBackupCodec(String codec) {
  return backupCodecs.contains(codec.toLowerCase());
}
