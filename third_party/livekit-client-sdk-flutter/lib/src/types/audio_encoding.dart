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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import 'priority.dart';

/// A type that represents audio encoding information.
@immutable
class AudioEncoding {
  /// Maximum bitrate for the audio track.
  final int maxBitrate;

  /// Priority for bandwidth allocation.
  final Priority? bitratePriority;

  /// Priority for DSCP marking. Requires `RTCConfiguration.isDscpEnabled` to be true.
  final Priority? networkPriority;

  const AudioEncoding({
    required this.maxBitrate,
    this.bitratePriority,
    this.networkPriority,
  });

  AudioEncoding copyWith({
    int? maxBitrate,
    Priority? bitratePriority,
    Priority? networkPriority,
  }) =>
      AudioEncoding(
        maxBitrate: maxBitrate ?? this.maxBitrate,
        bitratePriority: bitratePriority ?? this.bitratePriority,
        networkPriority: networkPriority ?? this.networkPriority,
      );

  @override
  String toString() =>
      '${runtimeType}(maxBitrate: ${maxBitrate}, bitratePriority: ${bitratePriority}, networkPriority: ${networkPriority})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioEncoding &&
          maxBitrate == other.maxBitrate &&
          bitratePriority == other.bitratePriority &&
          networkPriority == other.networkPriority;

  @override
  int get hashCode => Object.hash(maxBitrate, bitratePriority, networkPriority);

  static const presetTelephone = AudioEncoding(maxBitrate: 12000);
  static const presetSpeech = AudioEncoding(maxBitrate: 24000);
  static const presetMusic = AudioEncoding(maxBitrate: 48000);
  static const presetMusicStereo = AudioEncoding(maxBitrate: 64000);
  static const presetMusicHighQuality = AudioEncoding(maxBitrate: 96000);
  static const presetMusicHighQualityStereo = AudioEncoding(maxBitrate: 128000);

  static const presets = [
    presetTelephone,
    presetSpeech,
    presetMusic,
    presetMusicStereo,
    presetMusicHighQuality,
    presetMusicHighQualityStereo,
  ];
}

/// Convenience extension for [AudioEncoding].
extension AudioEncodingExt on AudioEncoding {
  rtc.RTCRtpEncoding toRTCRtpEncoding() => rtc.RTCRtpEncoding(
        maxBitrate: maxBitrate,
        priority: bitratePriority?.toRtcpPriorityType() ?? rtc.RTCPriorityType.low,
        networkPriority: networkPriority?.toRtcpPriorityType(),
      );
}
