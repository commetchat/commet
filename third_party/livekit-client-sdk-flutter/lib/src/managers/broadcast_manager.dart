// Copyright 2025 LiveKit, Inc.
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

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:meta/meta.dart';

import '../support/native.dart';

/// Manages broadcast state and track publication for screen sharing on iOS.
class BroadcastManager extends ChangeNotifier {
  static final BroadcastManager _instance = BroadcastManager._internal();
  BroadcastManager._internal();
  factory BroadcastManager() {
    return _instance;
  }

  bool _isBroadcasting = false;

  @internal
  void broadcastStateChanged(bool isBroadcasting) {
    _isBroadcasting = isBroadcasting;
    notifyListeners();
  }

  /// Indicates whether a broadcast is currently in progress.
  bool get isBroadcasting => _isBroadcasting;

  /// Determines whether a screen share track should be automatically published when broadcasting starts.
  ///
  /// Set this to `false` to manually manage track publication when the broadcast starts.
  ///
  bool shouldPublishTrack = true;

  /// Displays the system broadcast picker, allowing the user to start the broadcast.
  ///
  /// - Note: This is merely a request and does not guarantee the user will choose to start the broadcast.
  ///
  Future<void> requestActivation() async {
    await Native.broadcastRequestActivation();
  }

  /// Requests to stop the broadcast.
  ///
  /// If a screen share track is published, it will also be unpublished once the broadcast ends.
  /// This method has no effect if no broadcast is currently in progress.
  ///
  Future<void> requestStop() async {
    await Native.broadcastRequestStop();
  }
}
