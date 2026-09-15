// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomAgentDispatch _$RoomAgentDispatchFromJson(Map<String, dynamic> json) => RoomAgentDispatch(
      agentName: json['agent_name'] as String?,
      metadata: json['metadata'] as String?,
    );

Map<String, dynamic> _$RoomAgentDispatchToJson(RoomAgentDispatch instance) => <String, dynamic>{
      if (instance.agentName case final value?) 'agent_name': value,
      if (instance.metadata case final value?) 'metadata': value,
    };

RoomConfiguration _$RoomConfigurationFromJson(Map<String, dynamic> json) => RoomConfiguration(
      name: json['name'] as String?,
      emptyTimeout: (json['empty_timeout'] as num?)?.toInt(),
      departureTimeout: (json['departure_timeout'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      metadata: json['metadata'] as String?,
      minPlayoutDelay: (json['min_playout_delay'] as num?)?.toInt(),
      maxPlayoutDelay: (json['max_playout_delay'] as num?)?.toInt(),
      syncStreams: json['sync_streams'] as bool?,
      agents: (json['agents'] as List<dynamic>?)
          ?.map((e) => RoomAgentDispatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RoomConfigurationToJson(RoomConfiguration instance) => <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.emptyTimeout case final value?) 'empty_timeout': value,
      if (instance.departureTimeout case final value?) 'departure_timeout': value,
      if (instance.maxParticipants case final value?) 'max_participants': value,
      if (instance.metadata case final value?) 'metadata': value,
      if (instance.minPlayoutDelay case final value?) 'min_playout_delay': value,
      if (instance.maxPlayoutDelay case final value?) 'max_playout_delay': value,
      if (instance.syncStreams case final value?) 'sync_streams': value,
      if (instance.agents?.map((e) => e.toJson()).toList() case final value?) 'agents': value,
    };
