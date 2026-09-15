// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenRequestOptions _$TokenRequestOptionsFromJson(Map<String, dynamic> json) => TokenRequestOptions(
      roomName: json['roomName'] as String?,
      participantName: json['participantName'] as String?,
      participantIdentity: json['participantIdentity'] as String?,
      participantMetadata: json['participantMetadata'] as String?,
      participantAttributes: (json['participantAttributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      agentName: json['agentName'] as String?,
      agentMetadata: json['agentMetadata'] as String?,
    );

Map<String, dynamic> _$TokenRequestOptionsToJson(TokenRequestOptions instance) => <String, dynamic>{
      if (instance.roomName case final value?) 'roomName': value,
      if (instance.participantName case final value?) 'participantName': value,
      if (instance.participantIdentity case final value?) 'participantIdentity': value,
      if (instance.participantMetadata case final value?) 'participantMetadata': value,
      if (instance.participantAttributes case final value?) 'participantAttributes': value,
      if (instance.agentName case final value?) 'agentName': value,
      if (instance.agentMetadata case final value?) 'agentMetadata': value,
    };

TokenSourceRequest _$TokenSourceRequestFromJson(Map<String, dynamic> json) => TokenSourceRequest(
      roomName: json['room_name'] as String?,
      participantName: json['participant_name'] as String?,
      participantIdentity: json['participant_identity'] as String?,
      participantMetadata: json['participant_metadata'] as String?,
      participantAttributes: (json['participant_attributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      roomConfiguration:
          json['room_config'] == null ? null : RoomConfiguration.fromJson(json['room_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TokenSourceRequestToJson(TokenSourceRequest instance) => <String, dynamic>{
      if (instance.roomName case final value?) 'room_name': value,
      if (instance.participantName case final value?) 'participant_name': value,
      if (instance.participantIdentity case final value?) 'participant_identity': value,
      if (instance.participantMetadata case final value?) 'participant_metadata': value,
      if (instance.participantAttributes case final value?) 'participant_attributes': value,
      if (instance.roomConfiguration?.toJson() case final value?) 'room_config': value,
    };

TokenSourceResponse _$TokenSourceResponseFromJson(Map<String, dynamic> json) => TokenSourceResponse(
      serverUrl: json['server_url'] as String,
      participantToken: json['participant_token'] as String,
      participantName: json['participant_name'] as String?,
      roomName: json['room_name'] as String?,
    );

Map<String, dynamic> _$TokenSourceResponseToJson(TokenSourceResponse instance) => <String, dynamic>{
      'server_url': instance.serverUrl,
      'participant_token': instance.participantToken,
      if (instance.participantName case final value?) 'participant_name': value,
      if (instance.roomName case final value?) 'room_name': value,
    };
