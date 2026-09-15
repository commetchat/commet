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

/// A type that represents video encoding information.
@immutable
class VideoEncoding implements Comparable<VideoEncoding> {
  /// Maximum framerate for the video track.
  final int maxFramerate;

  /// Maximum bitrate for the video track.
  final int maxBitrate;

  /// Priority for bandwidth allocation.
  final Priority? bitratePriority;

  /// Priority for DSCP marking. Requires `RTCConfiguration.isDscpEnabled` to be true.
  final Priority? networkPriority;

  const VideoEncoding({
    required this.maxFramerate,
    required this.maxBitrate,
    this.bitratePriority,
    this.networkPriority,
  });

  VideoEncoding copyWith({
    int? maxFramerate,
    int? maxBitrate,
    Priority? bitratePriority,
    Priority? networkPriority,
  }) =>
      VideoEncoding(
        maxFramerate: maxFramerate ?? this.maxFramerate,
        maxBitrate: maxBitrate ?? this.maxBitrate,
        bitratePriority: bitratePriority ?? this.bitratePriority,
        networkPriority: networkPriority ?? this.networkPriority,
      );

  @override
  String toString() =>
      '${runtimeType}(maxFramerate: ${maxFramerate}, maxBitrate: ${maxBitrate}, bitratePriority: ${bitratePriority}, networkPriority: ${networkPriority})';

  // ----------------------------------------------------------------------
  // equality

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoEncoding &&
          maxFramerate == other.maxFramerate &&
          maxBitrate == other.maxBitrate &&
          bitratePriority == other.bitratePriority &&
          networkPriority == other.networkPriority;

  @override
  int get hashCode => Object.hash(maxFramerate, maxBitrate, bitratePriority, networkPriority);

  // ----------------------------------------------------------------------
  // Comparable

  @override
  int compareTo(VideoEncoding other) {
    // compare bitrates
    var result = maxBitrate.compareTo(other.maxBitrate);
    if (result != 0) return result;

    // compare by fps
    result = maxFramerate.compareTo(other.maxFramerate);
    if (result != 0) return result;

    // compare by priority fields for consistency with == and hashCode
    result = (bitratePriority?.index ?? -1).compareTo(other.bitratePriority?.index ?? -1);
    if (result != 0) return result;

    return (networkPriority?.index ?? -1).compareTo(other.networkPriority?.index ?? -1);
  }
}

/// Convenience extension for [VideoEncoding].
extension VideoEncodingExt on VideoEncoding {
  rtc.RTCRtpEncoding toRTCRtpEncoding({
    String? rid,
    double? scaleResolutionDownBy = 1.0,
    int? numTemporalLayers,
  }) =>
      rtc.RTCRtpEncoding(
        rid: rid,
        scaleResolutionDownBy: scaleResolutionDownBy,
        maxFramerate: maxFramerate,
        maxBitrate: maxBitrate,
        numTemporalLayers: numTemporalLayers,
        priority: bitratePriority?.toRtcpPriorityType() ?? rtc.RTCPriorityType.low,
        networkPriority: networkPriority?.toRtcpPriorityType(),
      );
}
