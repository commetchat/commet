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

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../events.dart';
import '../../internal/events.dart';
import '../../logger.dart';
import '../../stats/audio_source_stats.dart';
import '../../stats/stats.dart';
import '../../types/other.dart';
import '../audio_management.dart';
import '../local/local.dart';
import '../web/_audio_api.dart' if (dart.library.js_interop) '../web/_audio_html.dart' as audio;
import 'remote.dart';

class RemoteAudioTrack extends RemoteTrack with AudioTrack, RemoteAudioManagementMixin {
  String? _deviceId;
  RemoteAudioTrack(TrackSource source, rtc.MediaStream stream, rtc.MediaStreamTrack track,
      {rtc.RTCRtpReceiver? receiver})
      : super(
          TrackType.AUDIO,
          source,
          stream,
          track,
          receiver: receiver,
        );

  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      try {
        // web support
        await audio.startAudio(getCid(), mediaStreamTrack);
        if (_deviceId != null) {
          audio.setSinkId(getCid(), _deviceId!);
        }
      } catch (e) {
        if (e.toString().startsWith('NotAllowedError')) {
          events.emit(AudioPlaybackFailed(track: this));
        }
      }
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      // web support
      audio.stopAudio(getCid());
    }
    return didStop;
  }

  void setSinkId(String deviceId) {
    audio.setSinkId(getCid(), deviceId);
    _deviceId = deviceId;
  }

  AudioReceiverStats? prevStats;

  num? _currentBitrate;
  num? get currentBitrate => _currentBitrate;

  @override
  Future<bool> monitorStats() async {
    if (receiver == null || events.isDisposed || !isActive) {
      _currentBitrate = 0;
      return false;
    }
    try {
      final stats = await getReceiverStats();

      if (stats != null && prevStats != null && receiver != null) {
        final bitrate = computeBitrateForReceiverStats(stats, prevStats);
        _currentBitrate = bitrate;
        events.emit(AudioReceiverStatsEvent(stats: stats, currentBitrate: bitrate));
      }

      prevStats = stats;
    } catch (e) {
      logger.warning('failed to get sender stats: $e');
      return false;
    }
    return true;
  }

  Future<AudioReceiverStats?> getReceiverStats() async {
    if (receiver == null) {
      return null;
    }

    late List<rtc.StatsReport> stats;
    try {
      stats = await receiver!.getStats();
    } catch (e) {
      rethrow;
    }

    AudioReceiverStats? receiverStats;
    for (var v in stats) {
      if (v.type == 'inbound-rtp') {
        receiverStats ??= AudioReceiverStats(v.id, v.timestamp);

        receiverStats.jitter = getNumValFromReport(v.values, 'jitter');
        receiverStats.packetsLost = getNumValFromReport(v.values, 'packetsLost');
        receiverStats.jitterBufferDelay = getNumValFromReport(v.values, 'jitterBufferDelay');
        receiverStats.bytesReceived = getNumValFromReport(v.values, 'bytesReceived');
        receiverStats.packetsReceived = getNumValFromReport(v.values, 'packetsReceived');
        receiverStats.concealedSamples = getNumValFromReport(v.values, 'concealedSamples');
        receiverStats.concealmentEvents = getNumValFromReport(v.values, 'concealmentEvents');
        receiverStats.silentConcealedSamples = getNumValFromReport(v.values, 'silentConcealedSamples');
        receiverStats.silentConcealmentEvents = getNumValFromReport(v.values, 'silentConcealmentEvents');
        receiverStats.totalAudioEnergy = getNumValFromReport(v.values, 'totalAudioEnergy');
        receiverStats.totalSamplesDuration = getNumValFromReport(v.values, 'totalSamplesDuration');

        final c = stats.firstWhereOrNull((element) => element.type == 'codec');
        if (c != null) {
          receiverStats.mimeType = getStringValFromReport(c.values, 'mimeType');
          receiverStats.payloadType = getNumValFromReport(c.values, 'payloadType');
          receiverStats.channels = getNumValFromReport(c.values, 'channels');
          receiverStats.clockRate = getNumValFromReport(c.values, 'clockRate');
        }
      } else if (v.type == 'track') {
        receiverStats ??= AudioReceiverStats(v.id, v.timestamp);
        receiverStats.audioSourceStats = AudioSourceStats.fromReport(v);
      }
    }
    return receiverStats;
  }
}
