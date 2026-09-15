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

import 'package:collection/collection.dart';

import '../core/room.dart';
import '../participant/remote.dart';
import '../types/other.dart';
import 'constants.dart';

extension AgentRoom on Room {
  /// All agent participants currently in the room.
  ///
  /// - Note: This excludes participants that are publishing on behalf of
  ///   another participant (for example, "avatar worker" participants). Those
  ///   workers can be discovered by filtering [remoteParticipants] for
  ///   participants whose `lk.publish_on_behalf` attribute matches the agent's
  ///   identity.
  Iterable<RemoteParticipant> get agentParticipants => remoteParticipants.values.where(
        (participant) {
          if (participant.kind != ParticipantKind.AGENT) {
            return false;
          }
          final publishOnBehalf = participant.attributes[lkPublishOnBehalfAttributeKey];
          return publishOnBehalf == null || publishOnBehalf.isEmpty;
        },
      );

  /// The first agent participant in the room, if one exists.
  RemoteParticipant? get agentParticipant => agentParticipants.firstOrNull;
}
