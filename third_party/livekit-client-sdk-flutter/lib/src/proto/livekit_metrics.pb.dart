// This is a generated file - do not edit.
//
// Generated from livekit_metrics.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'livekit_metrics.pbenum.dart';

class MetricsBatch extends $pb.GeneratedMessage {
  factory MetricsBatch({
    $fixnum.Int64? timestampMs,
    $0.Timestamp? normalizedTimestamp,
    $core.Iterable<$core.String>? strData,
    $core.Iterable<TimeSeriesMetric>? timeSeries,
    $core.Iterable<EventMetric>? events,
  }) {
    final result = create();
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (normalizedTimestamp != null) result.normalizedTimestamp = normalizedTimestamp;
    if (strData != null) result.strData.addAll(strData);
    if (timeSeries != null) result.timeSeries.addAll(timeSeries);
    if (events != null) result.events.addAll(events);
    return result;
  }

  MetricsBatch._();

  factory MetricsBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MetricsBatch.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MetricsBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampMs')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'normalizedTimestamp', subBuilder: $0.Timestamp.create)
    ..pPS(3, _omitFieldNames ? '' : 'strData')
    ..pPM<TimeSeriesMetric>(4, _omitFieldNames ? '' : 'timeSeries', subBuilder: TimeSeriesMetric.create)
    ..pPM<EventMetric>(5, _omitFieldNames ? '' : 'events', subBuilder: EventMetric.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricsBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricsBatch copyWith(void Function(MetricsBatch) updates) =>
      super.copyWith((message) => updates(message as MetricsBatch)) as MetricsBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricsBatch create() => MetricsBatch._();
  @$core.override
  MetricsBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MetricsBatch getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MetricsBatch>(create);
  static MetricsBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampMs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get normalizedTimestamp => $_getN(1);
  @$pb.TagNumber(2)
  set normalizedTimestamp($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNormalizedTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearNormalizedTimestamp() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureNormalizedTimestamp() => $_ensure(1);

  /// To avoid repeating string values, we store them in a separate list and reference them by index
  /// This is useful for storing participant identities, track names, etc.
  /// There is also a predefined list of labels that can be used to reference common metrics.
  /// They have reserved indices from 0 to (METRIC_LABEL_PREDEFINED_MAX_VALUE - 1).
  /// Indexes pointing at str_data should start from METRIC_LABEL_PREDEFINED_MAX_VALUE,
  /// such that str_data[0] == index of METRIC_LABEL_PREDEFINED_MAX_VALUE.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get strData => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<TimeSeriesMetric> get timeSeries => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<EventMetric> get events => $_getList(4);
}

class TimeSeriesMetric extends $pb.GeneratedMessage {
  factory TimeSeriesMetric({
    $core.int? label,
    $core.int? participantIdentity,
    $core.int? trackSid,
    $core.Iterable<MetricSample>? samples,
    $core.int? rid,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (participantIdentity != null) result.participantIdentity = participantIdentity;
    if (trackSid != null) result.trackSid = trackSid;
    if (samples != null) result.samples.addAll(samples);
    if (rid != null) result.rid = rid;
    return result;
  }

  TimeSeriesMetric._();

  factory TimeSeriesMetric.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TimeSeriesMetric.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TimeSeriesMetric',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'), createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'label', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'participantIdentity', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'trackSid', fieldType: $pb.PbFieldType.OU3)
    ..pPM<MetricSample>(4, _omitFieldNames ? '' : 'samples', subBuilder: MetricSample.create)
    ..aI(5, _omitFieldNames ? '' : 'rid', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeSeriesMetric clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeSeriesMetric copyWith(void Function(TimeSeriesMetric) updates) =>
      super.copyWith((message) => updates(message as TimeSeriesMetric)) as TimeSeriesMetric;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeSeriesMetric create() => TimeSeriesMetric._();
  @$core.override
  TimeSeriesMetric createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TimeSeriesMetric getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeSeriesMetric>(create);
  static TimeSeriesMetric? _defaultInstance;

  /// Metric name e.g "speech_probablity". The string value is not directly stored in the message, but referenced by index
  /// in the `str_data` field of `MetricsBatch`
  @$pb.TagNumber(1)
  $core.int get label => $_getIZ(0);
  @$pb.TagNumber(1)
  set label($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get participantIdentity => $_getIZ(1);
  @$pb.TagNumber(2)
  set participantIdentity($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParticipantIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearParticipantIdentity() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get trackSid => $_getIZ(2);
  @$pb.TagNumber(3)
  set trackSid($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTrackSid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackSid() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<MetricSample> get samples => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get rid => $_getIZ(4);
  @$pb.TagNumber(5)
  set rid($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRid() => $_has(4);
  @$pb.TagNumber(5)
  void clearRid() => $_clearField(5);
}

class MetricSample extends $pb.GeneratedMessage {
  factory MetricSample({
    $fixnum.Int64? timestampMs,
    $0.Timestamp? normalizedTimestamp,
    $core.double? value,
  }) {
    final result = create();
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (normalizedTimestamp != null) result.normalizedTimestamp = normalizedTimestamp;
    if (value != null) result.value = value;
    return result;
  }

  MetricSample._();

  factory MetricSample.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MetricSample.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MetricSample',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestampMs')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'normalizedTimestamp', subBuilder: $0.Timestamp.create)
    ..aD(3, _omitFieldNames ? '' : 'value', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricSample clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricSample copyWith(void Function(MetricSample) updates) =>
      super.copyWith((message) => updates(message as MetricSample)) as MetricSample;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricSample create() => MetricSample._();
  @$core.override
  MetricSample createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MetricSample getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MetricSample>(create);
  static MetricSample? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampMs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get normalizedTimestamp => $_getN(1);
  @$pb.TagNumber(2)
  set normalizedTimestamp($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNormalizedTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearNormalizedTimestamp() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureNormalizedTimestamp() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get value => $_getN(2);
  @$pb.TagNumber(3)
  set value($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => $_clearField(3);
}

class EventMetric extends $pb.GeneratedMessage {
  factory EventMetric({
    $core.int? label,
    $core.int? participantIdentity,
    $core.int? trackSid,
    $fixnum.Int64? startTimestampMs,
    $fixnum.Int64? endTimestampMs,
    $0.Timestamp? normalizedStartTimestamp,
    $0.Timestamp? normalizedEndTimestamp,
    $core.String? metadata,
    $core.int? rid,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (participantIdentity != null) result.participantIdentity = participantIdentity;
    if (trackSid != null) result.trackSid = trackSid;
    if (startTimestampMs != null) result.startTimestampMs = startTimestampMs;
    if (endTimestampMs != null) result.endTimestampMs = endTimestampMs;
    if (normalizedStartTimestamp != null) result.normalizedStartTimestamp = normalizedStartTimestamp;
    if (normalizedEndTimestamp != null) result.normalizedEndTimestamp = normalizedEndTimestamp;
    if (metadata != null) result.metadata = metadata;
    if (rid != null) result.rid = rid;
    return result;
  }

  EventMetric._();

  factory EventMetric.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventMetric.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EventMetric',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'), createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'label', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'participantIdentity', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'trackSid', fieldType: $pb.PbFieldType.OU3)
    ..aInt64(4, _omitFieldNames ? '' : 'startTimestampMs')
    ..aInt64(5, _omitFieldNames ? '' : 'endTimestampMs')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'normalizedStartTimestamp', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'normalizedEndTimestamp', subBuilder: $0.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'metadata')
    ..aI(9, _omitFieldNames ? '' : 'rid', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventMetric clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventMetric copyWith(void Function(EventMetric) updates) =>
      super.copyWith((message) => updates(message as EventMetric)) as EventMetric;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventMetric create() => EventMetric._();
  @$core.override
  EventMetric createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventMetric getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventMetric>(create);
  static EventMetric? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get label => $_getIZ(0);
  @$pb.TagNumber(1)
  set label($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get participantIdentity => $_getIZ(1);
  @$pb.TagNumber(2)
  set participantIdentity($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParticipantIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearParticipantIdentity() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get trackSid => $_getIZ(2);
  @$pb.TagNumber(3)
  set trackSid($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTrackSid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackSid() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimestampMs => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimestampMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartTimestampMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimestampMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimestampMs => $_getI64(4);
  @$pb.TagNumber(5)
  set endTimestampMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEndTimestampMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimestampMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Timestamp get normalizedStartTimestamp => $_getN(5);
  @$pb.TagNumber(6)
  set normalizedStartTimestamp($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasNormalizedStartTimestamp() => $_has(5);
  @$pb.TagNumber(6)
  void clearNormalizedStartTimestamp() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureNormalizedStartTimestamp() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.Timestamp get normalizedEndTimestamp => $_getN(6);
  @$pb.TagNumber(7)
  set normalizedEndTimestamp($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasNormalizedEndTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearNormalizedEndTimestamp() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureNormalizedEndTimestamp() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get metadata => $_getSZ(7);
  @$pb.TagNumber(8)
  set metadata($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetadata() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get rid => $_getIZ(8);
  @$pb.TagNumber(9)
  set rid($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRid() => $_has(8);
  @$pb.TagNumber(9)
  void clearRid() => $_clearField(9);
}

class MetricsRecordingHeader extends $pb.GeneratedMessage {
  factory MetricsRecordingHeader({
    $core.String? roomId,
    $fixnum.Int64? duration,
    $0.Timestamp? startTime,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? roomTags,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (duration != null) result.duration = duration;
    if (startTime != null) result.startTime = startTime;
    if (roomTags != null) result.roomTags.addEntries(roomTags);
    return result;
  }

  MetricsRecordingHeader._();

  factory MetricsRecordingHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MetricsRecordingHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MetricsRecordingHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'livekit'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'duration', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'startTime', subBuilder: $0.Timestamp.create)
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'roomTags',
        entryClassName: 'MetricsRecordingHeader.RoomTagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('livekit'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricsRecordingHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricsRecordingHeader copyWith(void Function(MetricsRecordingHeader) updates) =>
      super.copyWith((message) => updates(message as MetricsRecordingHeader)) as MetricsRecordingHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricsRecordingHeader create() => MetricsRecordingHeader._();
  @$core.override
  MetricsRecordingHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MetricsRecordingHeader getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MetricsRecordingHeader>(create);
  static MetricsRecordingHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get duration => $_getI64(1);
  @$pb.TagNumber(3)
  set duration($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(3)
  $core.bool hasDuration() => $_has(1);
  @$pb.TagNumber(3)
  void clearDuration() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get startTime => $_getN(2);
  @$pb.TagNumber(4)
  set startTime($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartTime() => $_has(2);
  @$pb.TagNumber(4)
  void clearStartTime() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureStartTime() => $_ensure(2);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get roomTags => $_getMap(3);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
