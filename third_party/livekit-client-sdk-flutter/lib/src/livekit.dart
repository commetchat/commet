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

import 'support/native.dart';
import 'support/platform.dart' show lkPlatformIsMobile;

/// Main entry point to connect to a room.
/// {@category Room}
class LiveKitClient {
  static const version = '2.7.0';

  /// Initialize the WebRTC plugin. If this is not manually called, will be
  /// initialized with default settings.
  /// This method must be called before calling any LiveKit SDK API.
  static Future<void> initialize({bool bypassVoiceProcessing = false}) async {
    if (lkPlatformIsMobile()) {
      await rtc.WebRTC.initialize(options: {
        if (bypassVoiceProcessing) 'bypassVoiceProcessing': bypassVoiceProcessing,
      });

      Native.bypassVoiceProcessing = bypassVoiceProcessing;
    }
  }
}
