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

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../../events.dart';
import '../../logger.dart';
import '../../options.dart';
import '../../stats/audio_source_stats.dart';
import '../../stats/stats.dart';
import '../../types/other.dart';
import '../audio_management.dart';
import '../options.dart';
import 'local.dart';

class LocalAudioTrack extends LocalTrack with AudioTrack, LocalAudioManagementMixin {
  // Options used for this track
  @override
  covariant AudioCaptureOptions currentOptions;

  AudioPublishOptions? lastPublishOptions;

  Future<void> setDeviceId(String deviceId) async {
    if (currentOptions.deviceId == deviceId) {
      return;
    }
    currentOptions = currentOptions.copyWith(deviceId: deviceId);
    if (!muted) {
      await restartTrack();
    }
  }

  num? _currentBitrate;
  num? get currentBitrate => _currentBitrate;

  AudioSenderStats? prevStats;

  @override
  Future<bool> monitorStats() async {
    if (events.isDisposed || !isActive) {
      _currentBitrate = 0;
      return false;
    }
    try {
      final stats = await getSenderStats();

      if (stats != null && prevStats != null && sender != null) {
        final bitrate = computeBitrateForSenderStats(stats, prevStats);
        _currentBitrate = bitrate;
        events.emit(AudioSenderStatsEvent(stats: stats, currentBitrate: bitrate));
      }

      prevStats = stats;
    } catch (e) {
      logger.warning('failed to get sender stats: $e');
      return false;
    }
    return true;
  }

  Future<AudioSenderStats?> getSenderStats() async {
    if (sender == null) {
      return null;
    }

    late List<rtc.StatsReport> stats;
    try {
      stats = await sender!.getStats();
    } catch (e) {
      rethrow;
    }

    AudioSenderStats? senderStats;
    for (var v in stats) {
      if (v.type == 'outbound-rtp') {
        senderStats ??= AudioSenderStats(v.id, v.timestamp);
        senderStats.packetsSent = getNumValFromReport(v.values, 'packetsSent');
        senderStats.packetsLost = getNumValFromReport(v.values, 'packetsLost');
        senderStats.bytesSent = getNumValFromReport(v.values, 'bytesSent');
        senderStats.roundTripTime = getNumValFromReport(v.values, 'roundTripTime');
        senderStats.jitter = getNumValFromReport(v.values, 'jitter');

        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          senderStats.mimeType = getStringValFromReport(c.values, 'mimeType');
          senderStats.payloadType = getNumValFromReport(c.values, 'payloadType');
          senderStats.channels = getNumValFromReport(c.values, 'channels');
          senderStats.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
      } else if (v.type == 'media-source') {
        senderStats ??= AudioSenderStats(v.id, v.timestamp);
        senderStats.audioSourceStats = AudioSourceStats.fromReport(v);
      }
    }
    return senderStats;
  }

  // private constructor
  @internal
  LocalAudioTrack(
    TrackSource source,
    rtc.MediaStream stream,
    rtc.MediaStreamTrack track,
    this.currentOptions,
  ) : super(
          TrackType.AUDIO,
          source,
          stream,
          track,
        );

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> create([
    AudioCaptureOptions? options,
  ]) async {
    options ??= const AudioCaptureOptions();
    final stream = await LocalTrack.createStream(options);

    final track = LocalAudioTrack(
      TrackSource.microphone,
      stream,
      stream.getAudioTracks().first,
      options,
    );

    if (options.processor != null) {
      await track.setProcessor(options.processor);
    }

    return track;
  }
}
