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

// https://developer.apple.com/documentation/avfaudio/avaudiosession/category
enum AppleAudioCategory {
  soloAmbient,
  playback,
  record,
  playAndRecord,
  multiRoute,
}

// https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
enum AppleAudioCategoryOption {
  mixWithOthers, // Only playAndRecord, playback, or multiRoute.
  duckOthers, // Only playAndRecord, playback, or multiRoute.
  interruptSpokenAudioAndMixWithOthers,
  allowBluetooth, // Only playAndRecord or record.
  allowBluetoothA2DP,
  allowAirPlay,
  defaultToSpeaker,
}

// https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
enum AppleAudioMode {
  default_,
  gameChat,
  measurement,
  moviePlayback,
  spokenAudio,
  videoChat,
  videoRecording,
  voiceChat,
  voicePrompt,
}

extension AppleAudioCategoryExt on AppleAudioCategory {
  String toStringValue() => <AppleAudioCategory, String>{
        AppleAudioCategory.soloAmbient: 'soloAmbient',
        AppleAudioCategory.playback: 'playback',
        AppleAudioCategory.record: 'record',
        AppleAudioCategory.playAndRecord: 'playAndRecord',
        AppleAudioCategory.multiRoute: 'multiRoute',
      }[this]!;
}

extension AppleAudioCategoryOptionExt on AppleAudioCategoryOption {
  String toStringValue() => <AppleAudioCategoryOption, String>{
        AppleAudioCategoryOption.mixWithOthers: 'mixWithOthers',
        AppleAudioCategoryOption.duckOthers: 'duckOthers',
        AppleAudioCategoryOption.interruptSpokenAudioAndMixWithOthers: 'interruptSpokenAudioAndMixWithOthers',
        AppleAudioCategoryOption.allowBluetooth: 'allowBluetooth',
        AppleAudioCategoryOption.allowBluetoothA2DP: 'allowBluetoothA2DP',
        AppleAudioCategoryOption.allowAirPlay: 'allowAirPlay',
        AppleAudioCategoryOption.defaultToSpeaker: 'defaultToSpeaker',
      }[this]!;
}

extension AppleAudioModeExt on AppleAudioMode {
  String toStringValue() => <AppleAudioMode, String>{
        AppleAudioMode.default_: 'default',
        AppleAudioMode.gameChat: 'gameChat',
        AppleAudioMode.measurement: 'measurement',
        AppleAudioMode.moviePlayback: 'moviePlayback',
        AppleAudioMode.spokenAudio: 'spokenAudio',
        AppleAudioMode.videoChat: 'videoChat',
        AppleAudioMode.videoRecording: 'videoRecording',
        AppleAudioMode.voiceChat: 'voiceChat',
        AppleAudioMode.voicePrompt: 'voicePrompt',
      }[this]!;
}

class NativeAudioConfiguration {
  final AppleAudioCategory? appleAudioCategory;
  final Set<AppleAudioCategoryOption>? appleAudioCategoryOptions;
  final AppleAudioMode? appleAudioMode;
  final bool? preferSpeakerOutput;

  static final soloAmbient = NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.soloAmbient,
    appleAudioCategoryOptions: {},
    appleAudioMode: AppleAudioMode.default_,
  );

  static final playback = NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.playback,
    appleAudioCategoryOptions: {AppleAudioCategoryOption.mixWithOthers},
    appleAudioMode: AppleAudioMode.spokenAudio,
  );

  static final playAndRecordSpeaker = NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.playAndRecord,
    appleAudioCategoryOptions: {
      AppleAudioCategoryOption.allowBluetooth,
      AppleAudioCategoryOption.allowBluetoothA2DP,
      AppleAudioCategoryOption.allowAirPlay,
    },
    appleAudioMode: AppleAudioMode.videoChat,
  );

  static final playAndRecordReceiver = NativeAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.playAndRecord,
    appleAudioCategoryOptions: {
      AppleAudioCategoryOption.allowBluetooth,
      AppleAudioCategoryOption.allowBluetoothA2DP,
      AppleAudioCategoryOption.allowAirPlay,
    },
    appleAudioMode: AppleAudioMode.voiceChat,
  );

  NativeAudioConfiguration(
      {
      // for iOS / Mac
      this.appleAudioCategory,
      this.appleAudioCategoryOptions,
      this.appleAudioMode,
      this.preferSpeakerOutput
      // Android options
      // ...
      });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (appleAudioCategory != null) 'appleAudioCategory': appleAudioCategory!.toStringValue(),
        if (appleAudioCategoryOptions != null)
          'appleAudioCategoryOptions': appleAudioCategoryOptions!.map((e) => e.toStringValue()).toList(),
        if (appleAudioMode != null) 'appleAudioMode': appleAudioMode!.toStringValue(),
        if (preferSpeakerOutput != null) 'preferSpeakerOutput': preferSpeakerOutput,
      };

  NativeAudioConfiguration copyWith({
    AppleAudioCategory? appleAudioCategory,
    Set<AppleAudioCategoryOption>? appleAudioCategoryOptions,
    AppleAudioMode? appleAudioMode,
    bool? preferSpeakerOutput,
  }) =>
      NativeAudioConfiguration(
        appleAudioCategory: appleAudioCategory ?? this.appleAudioCategory,
        appleAudioCategoryOptions: appleAudioCategoryOptions ?? this.appleAudioCategoryOptions,
        appleAudioMode: appleAudioMode ?? this.appleAudioMode,
        preferSpeakerOutput: preferSpeakerOutput ?? this.preferSpeakerOutput,
      );
}
