import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../agent/constants.dart';

part 'agent_attributes.g.dart';

AgentAttributes agentAttributesFromJson(String source) =>
    AgentAttributes.fromJson(jsonDecode(source) as Map<String, dynamic>);

String agentAttributesToJson(AgentAttributes value) => jsonEncode(value.toJson());

TranscriptionAttributes transcriptionAttributesFromJson(String source) =>
    TranscriptionAttributes.fromJson(jsonDecode(source) as Map<String, dynamic>);

String transcriptionAttributesToJson(TranscriptionAttributes value) => jsonEncode(value.toJson());

@JsonSerializable()
class AgentAttributes {
  const AgentAttributes({
    this.lkAgentInputs,
    this.lkAgentOutputs,
    this.lkAgentState,
    this.lkPublishOnBehalf,
  });

  @JsonKey(name: lkAgentInputsAttributeKey)
  final List<AgentInput>? lkAgentInputs;

  @JsonKey(name: lkAgentOutputsAttributeKey)
  final List<AgentOutput>? lkAgentOutputs;

  @JsonKey(name: lkAgentStateAttributeKey)
  final AgentState? lkAgentState;

  @JsonKey(name: lkPublishOnBehalfAttributeKey)
  final String? lkPublishOnBehalf;

  factory AgentAttributes.fromJson(Map<String, dynamic> json) => _$AgentAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$AgentAttributesToJson(this);
}

@JsonEnum(alwaysCreate: true)
enum AgentInput {
  @JsonValue('audio')
  audio,
  @JsonValue('text')
  text,
  @JsonValue('video')
  video,
}

@JsonEnum(alwaysCreate: true)
enum AgentOutput {
  @JsonValue('audio')
  audio,
  @JsonValue('transcription')
  transcription,
}

@JsonEnum(alwaysCreate: true)
enum AgentState {
  @JsonValue('idle')
  idle,
  @JsonValue('initializing')
  initializing,
  @JsonValue('listening')
  listening,
  @JsonValue('speaking')
  speaking,
  @JsonValue('thinking')
  thinking,
}

@JsonSerializable()
class TranscriptionAttributes {
  /// Schema for transcription-related text stream attributes.
  ///
  /// These attributes are attached to LiveKit text streams used for agent and
  /// user transcriptions (typically on the `'lk.transcription'` topic).
  ///
  /// - Note: Some agent implementations may encode `lk.transcription_final` as a
  ///   boolean or a string (`"true"`/`"false"`/`"1"`/`"0"`). This model accepts
  ///   both forms.
  const TranscriptionAttributes({
    this.lkSegmentId,
    this.lkTranscribedTrackId,
    this.lkTranscriptionFinal,
  });

  /// Stable identifier for the transcript segment (`lk.segment_id`).
  ///
  /// A segment id remains stable for the lifetime of a transcript segment and
  /// can be used to reconcile incremental updates in UIs.
  @JsonKey(name: 'lk.segment_id')
  final String? lkSegmentId;

  /// Track id associated with the transcription (`lk.transcribed_track_id`).
  @JsonKey(name: 'lk.transcribed_track_id')
  final String? lkTranscribedTrackId;

  /// Whether this segment is finalized (`lk.transcription_final`).
  @JsonKey(name: 'lk.transcription_final', fromJson: _boolFromJson, toJson: _boolToJson)
  final bool? lkTranscriptionFinal;

  factory TranscriptionAttributes.fromJson(Map<String, dynamic> json) => _$TranscriptionAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionAttributesToJson(this);
}

bool? _boolFromJson(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') {
      return true;
    }
    if (lower == 'false' || lower == '0') {
      return false;
    }
  }
  return null;
}

Object? _boolToJson(bool? value) => value;
