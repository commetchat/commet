// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rfc8984.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RFC8984CalendarEvent _$RFC8984CalendarEventFromJson(
        Map<String, dynamic> json) =>
    RFC8984CalendarEvent(
      uid: json['uid'] as String,
      updated: const IsoDateTimeConverter().fromJson(json['updated'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      start: const IsoDateTimeConverter().fromJson(json['start'] as String),
      duration:
          const IsoDurationConverter().fromJson(json['duration'] as String),
      timeZone: json['timeZone'] as String?,
      recurrenceRules: (json['recurrenceRules'] as List<dynamic>?)
          ?.map(
              (e) => RFC8984RecurrenceRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      locations: (json['locations'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, RFC8984Location.fromJson(e as Map<String, dynamic>)),
      ),
      virtualLocations:
          (json['virtualLocations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, RFC8984VirtualLocation.fromJson(e as Map<String, dynamic>)),
      ),
      localizations: (json['localizations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
      ),
      recurrenceOverrides: json['recurrenceOverrides'] as Map<String, dynamic>?,
    )..locale = json['locale'] as String?;

Map<String, dynamic> _$RFC8984CalendarEventToJson(
        RFC8984CalendarEvent instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'updated': const IsoDateTimeConverter().toJson(instance.updated),
      'title': instance.title,
      if (instance.description case final value?) 'description': value,
      'start': const IsoDateTimeConverter().toJson(instance.start),
      if (instance.timeZone case final value?) 'timeZone': value,
      'duration': const IsoDurationConverter().toJson(instance.duration),
      if (instance.locale case final value?) 'locale': value,
      if (instance.recurrenceRules case final value?) 'recurrenceRules': value,
      if (instance.recurrenceOverrides case final value?)
        'recurrenceOverrides': value,
      if (instance.locations case final value?) 'locations': value,
      if (instance.virtualLocations case final value?)
        'virtualLocations': value,
      if (instance.localizations case final value?) 'localizations': value,
    };

RFC8984Location _$RFC8984LocationFromJson(Map<String, dynamic> json) =>
    RFC8984Location(
      rel: json['rel'] as String?,
      name: json['name'] as String?,
      title: json['title'] as String?,
      timeZone: json['timeZone'] as String?,
      description: json['description'] as String?,
      coordinates: json['coordinates'] as String?,
    );

Map<String, dynamic> _$RFC8984LocationToJson(RFC8984Location instance) =>
    <String, dynamic>{
      if (instance.rel case final value?) 'rel': value,
      if (instance.name case final value?) 'name': value,
      if (instance.title case final value?) 'title': value,
      if (instance.timeZone case final value?) 'timeZone': value,
      if (instance.description case final value?) 'description': value,
      if (instance.coordinates case final value?) 'coordinates': value,
    };

RFC8984VirtualLocation _$RFC8984VirtualLocationFromJson(
        Map<String, dynamic> json) =>
    RFC8984VirtualLocation(
      rel: json['rel'] as String?,
      name: json['name'] as String?,
      timeZone: json['timeZone'] as String?,
    )..uri = json['uri'] as String?;

Map<String, dynamic> _$RFC8984VirtualLocationToJson(
        RFC8984VirtualLocation instance) =>
    <String, dynamic>{
      if (instance.rel case final value?) 'rel': value,
      if (instance.name case final value?) 'name': value,
      if (instance.timeZone case final value?) 'timeZone': value,
      if (instance.uri case final value?) 'uri': value,
    };

RFC8984RecurrenceRule _$RFC8984RecurrenceRuleFromJson(
        Map<String, dynamic> json) =>
    RFC8984RecurrenceRule(
      frequency: json['frequency'] as String,
      until: _$JsonConverterFromJson<String, DateTime>(
          json['until'], const IsoDateTimeConverter().fromJson),
    );

Map<String, dynamic> _$RFC8984RecurrenceRuleToJson(
        RFC8984RecurrenceRule instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      if (_$JsonConverterToJson<String, DateTime>(
              instance.until, const IsoDateTimeConverter().toJson)
          case final value?)
        'until': value,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
