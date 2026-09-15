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

import '../proto/livekit_models.pb.dart' as lk_models;

/// Represents the state of a participant in the room.
enum ParticipantState {
  /// Websocket is connected, but no offer has been sent yet
  joining,

  /// Server has received the client's offer
  joined,

  /// ICE connectivity has been established
  active,

  /// Websocket has disconnected
  disconnected,

  /// Unknown state
  unknown,
}

extension ParticipantStateExt on lk_models.ParticipantInfo_State {
  ParticipantState toLKType() => switch (this) {
        lk_models.ParticipantInfo_State.JOINING => ParticipantState.joining,
        lk_models.ParticipantInfo_State.JOINED => ParticipantState.joined,
        lk_models.ParticipantInfo_State.ACTIVE => ParticipantState.active,
        lk_models.ParticipantInfo_State.DISCONNECTED => ParticipantState.disconnected,
        _ => ParticipantState.unknown,
      };
}
