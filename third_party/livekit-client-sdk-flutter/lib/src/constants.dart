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

class Timeouts {
  final Duration connection;
  final Duration debounce;
  final Duration publish;
  final Duration subscribe;
  final Duration peerConnection;
  final Duration iceRestart;

  const Timeouts({
    required this.connection,
    required this.debounce,
    required this.publish,
    required this.subscribe,
    required this.peerConnection,
    required this.iceRestart,
  });

  static const Timeouts defaultTimeouts = Timeouts(
    connection: Duration(seconds: 10),
    debounce: Duration(milliseconds: 20),
    publish: Duration(seconds: 10),
    subscribe: Duration(seconds: 10),
    peerConnection: Duration(seconds: 10),
    iceRestart: Duration(seconds: 10),
  );
}
