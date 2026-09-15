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

import 'stats.dart';

class AudioSourceStats {
  final num? audioLevel;
  final num? totalAudioEnergy;
  final num? totalSamplesDuration;
  final num? echoReturnLoss;
  final num? echoReturnLossEnhancement;
  final String? trackIdentifier;
  final bool remoteSource;

  AudioSourceStats({
    required this.echoReturnLossEnhancement,
    required this.audioLevel,
    required this.totalAudioEnergy,
    required this.totalSamplesDuration,
    required this.echoReturnLoss,
    required this.trackIdentifier,
    required this.remoteSource,
  });

  factory AudioSourceStats.fromReport(rtc.StatsReport report) {
    return AudioSourceStats(
      echoReturnLossEnhancement: getNumValFromReport(report.values, 'echoReturnLossEnhancement'),
      audioLevel: getNumValFromReport(report.values, 'audioLevel'),
      totalAudioEnergy: getNumValFromReport(report.values, 'totalAudioEnergy'),
      totalSamplesDuration: getNumValFromReport(report.values, 'totalSamplesDuration'),
      echoReturnLoss: getNumValFromReport(report.values, 'echoReturnLoss'),
      trackIdentifier: getStringValFromReport(report.values, 'trackIdentifier'),
      remoteSource: getBoolValFromReport(report.values, 'remoteSource'),
    );
  }
}
