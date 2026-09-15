// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_attributes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentAttributes _$AgentAttributesFromJson(Map<String, dynamic> json) => AgentAttributes(
      lkAgentInputs:
          (json['lk.agent.inputs'] as List<dynamic>?)?.map((e) => $enumDecode(_$AgentInputEnumMap, e)).toList(),
      lkAgentOutputs:
          (json['lk.agent.outputs'] as List<dynamic>?)?.map((e) => $enumDecode(_$AgentOutputEnumMap, e)).toList(),
      lkAgentState: $enumDecodeNullable(_$AgentStateEnumMap, json['lk.agent.state']),
      lkPublishOnBehalf: json['lk.publish_on_behalf'] as String?,
    );

Map<String, dynamic> _$AgentAttributesToJson(AgentAttributes instance) => <String, dynamic>{
      if (instance.lkAgentInputs?.map((e) => _$AgentInputEnumMap[e]!).toList() case final value?)
        'lk.agent.inputs': value,
      if (instance.lkAgentOutputs?.map((e) => _$AgentOutputEnumMap[e]!).toList() case final value?)
        'lk.agent.outputs': value,
      if (_$AgentStateEnumMap[instance.lkAgentState] case final value?) 'lk.agent.state': value,
      if (instance.lkPublishOnBehalf case final value?) 'lk.publish_on_behalf': value,
    };

const _$AgentInputEnumMap = {
  AgentInput.audio: 'audio',
  AgentInput.text: 'text',
  AgentInput.video: 'video',
};

const _$AgentOutputEnumMap = {
  AgentOutput.audio: 'audio',
  AgentOutput.transcription: 'transcription',
};

const _$AgentStateEnumMap = {
  AgentState.idle: 'idle',
  AgentState.initializing: 'initializing',
  AgentState.listening: 'listening',
  AgentState.speaking: 'speaking',
  AgentState.thinking: 'thinking',
};

TranscriptionAttributes _$TranscriptionAttributesFromJson(Map<String, dynamic> json) => TranscriptionAttributes(
      lkSegmentId: json['lk.segment_id'] as String?,
      lkTranscribedTrackId: json['lk.transcribed_track_id'] as String?,
      lkTranscriptionFinal: _boolFromJson(json['lk.transcription_final']),
    );

Map<String, dynamic> _$TranscriptionAttributesToJson(TranscriptionAttributes instance) => <String, dynamic>{
      if (instance.lkSegmentId case final value?) 'lk.segment_id': value,
      if (instance.lkTranscribedTrackId case final value?) 'lk.transcribed_track_id': value,
      if (_boolToJson(instance.lkTranscriptionFinal) case final value?) 'lk.transcription_final': value,
    };
