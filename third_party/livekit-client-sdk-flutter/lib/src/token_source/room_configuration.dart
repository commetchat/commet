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

import 'package:json_annotation/json_annotation.dart';

part 'room_configuration.g.dart';

/// Configuration for dispatching an agent to a room.
@JsonSerializable()
class RoomAgentDispatch {
  /// Name of the agent to dispatch.
  @JsonKey(name: 'agent_name')
  final String? agentName;

  /// Metadata for the agent.
  final String? metadata;

  const RoomAgentDispatch({
    this.agentName,
    this.metadata,
  });

  factory RoomAgentDispatch.fromJson(Map<String, dynamic> json) => _$RoomAgentDispatchFromJson(json);
  Map<String, dynamic> toJson() => _$RoomAgentDispatchToJson(this);
}

/// Configuration for a LiveKit room.
///
/// This class contains various settings that control room behavior such as timeouts,
/// participant limits, and agent dispatching.
@JsonSerializable()
class RoomConfiguration {
  /// Room name, used as ID, must be unique.
  final String? name;

  /// Number of seconds to keep the room open if no one joins.
  @JsonKey(name: 'empty_timeout')
  final int? emptyTimeout;

  /// Number of seconds to keep the room open after everyone leaves.
  @JsonKey(name: 'departure_timeout')
  final int? departureTimeout;

  /// Limit number of participants that can be in a room, excluding Egress and Ingress participants.
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;

  /// Metadata of room.
  final String? metadata;

  /// Minimum playout delay of subscriber.
  @JsonKey(name: 'min_playout_delay')
  final int? minPlayoutDelay;

  /// Maximum playout delay of subscriber.
  @JsonKey(name: 'max_playout_delay')
  final int? maxPlayoutDelay;

  /// Improves A/V sync when playout delay set to a value larger than 200ms.
  /// It will disable transceiver re-use so not recommended for rooms with frequent subscription changes.
  @JsonKey(name: 'sync_streams')
  final bool? syncStreams;

  /// Define agents that should be dispatched to this room.
  final List<RoomAgentDispatch>? agents;

  const RoomConfiguration({
    this.name,
    this.emptyTimeout,
    this.departureTimeout,
    this.maxParticipants,
    this.metadata,
    this.minPlayoutDelay,
    this.maxPlayoutDelay,
    this.syncStreams,
    this.agents,
  });

  factory RoomConfiguration.fromJson(Map<String, dynamic> json) => _$RoomConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$RoomConfigurationToJson(this);
}
