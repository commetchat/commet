// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveKitVideoGrant _$LiveKitVideoGrantFromJson(Map<String, dynamic> json) => LiveKitVideoGrant(
      room: json['room'] as String?,
      roomCreate: json['room_create'] as bool?,
      roomJoin: json['room_join'] as bool?,
      roomList: json['room_list'] as bool?,
      roomRecord: json['room_record'] as bool?,
      roomAdmin: json['room_admin'] as bool?,
      canPublish: json['can_publish'] as bool?,
      canSubscribe: json['can_subscribe'] as bool?,
      canPublishData: json['can_publish_data'] as bool?,
      canPublishSources: (json['can_publish_sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hidden: json['hidden'] as bool?,
      recorder: json['recorder'] as bool?,
    );

Map<String, dynamic> _$LiveKitVideoGrantToJson(LiveKitVideoGrant instance) => <String, dynamic>{
      if (instance.room case final value?) 'room': value,
      if (instance.roomCreate case final value?) 'room_create': value,
      if (instance.roomJoin case final value?) 'room_join': value,
      if (instance.roomList case final value?) 'room_list': value,
      if (instance.roomRecord case final value?) 'room_record': value,
      if (instance.roomAdmin case final value?) 'room_admin': value,
      if (instance.canPublish case final value?) 'can_publish': value,
      if (instance.canSubscribe case final value?) 'can_subscribe': value,
      if (instance.canPublishData case final value?) 'can_publish_data': value,
      if (instance.canPublishSources case final value?) 'can_publish_sources': value,
      if (instance.hidden case final value?) 'hidden': value,
      if (instance.recorder case final value?) 'recorder': value,
    };
