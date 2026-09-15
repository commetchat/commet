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

/// Priority levels for RTP encoding parameters.
///
/// `bitratePriority` controls WebRTC internal bandwidth allocation between streams.
/// `networkPriority` controls DSCP marking for network-level QoS.
enum Priority {
  veryLow,
  low,
  medium,
  high,
}

extension PriorityExt on Priority {
  rtc.RTCPriorityType toRtcpPriorityType() {
    switch (this) {
      case Priority.veryLow:
        return rtc.RTCPriorityType.veryLow;
      case Priority.low:
        return rtc.RTCPriorityType.low;
      case Priority.medium:
        return rtc.RTCPriorityType.medium;
      case Priority.high:
        return rtc.RTCPriorityType.high;
    }
  }
}
