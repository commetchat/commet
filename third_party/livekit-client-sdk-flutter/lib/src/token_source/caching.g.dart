// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caching.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenStoreItem _$TokenStoreItemFromJson(Map<String, dynamic> json) => TokenStoreItem(
      options: TokenRequestOptions.fromJson(json['options'] as Map<String, dynamic>),
      response: TokenSourceResponse.fromJson(json['response'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TokenStoreItemToJson(TokenStoreItem instance) => <String, dynamic>{
      'options': instance.options.toJson(),
      'response': instance.response.toJson(),
    };
