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

import 'package:protobuf/protobuf.dart' as $pb;

/// index from [0: MAX_LABEL_PREDEFINED_MAX_VALUE) are for predefined labels (`MetricLabel`)
class MetricLabel extends $pb.ProtobufEnum {
  static const MetricLabel AGENTS_LLM_TTFT = MetricLabel._(0, _omitEnumNames ? '' : 'AGENTS_LLM_TTFT');
  static const MetricLabel AGENTS_STT_TTFT = MetricLabel._(1, _omitEnumNames ? '' : 'AGENTS_STT_TTFT');
  static const MetricLabel AGENTS_TTS_TTFB = MetricLabel._(2, _omitEnumNames ? '' : 'AGENTS_TTS_TTFB');
  static const MetricLabel CLIENT_VIDEO_SUBSCRIBER_FREEZE_COUNT =
      MetricLabel._(3, _omitEnumNames ? '' : 'CLIENT_VIDEO_SUBSCRIBER_FREEZE_COUNT');
  static const MetricLabel CLIENT_VIDEO_SUBSCRIBER_TOTAL_FREEZE_DURATION =
      MetricLabel._(4, _omitEnumNames ? '' : 'CLIENT_VIDEO_SUBSCRIBER_TOTAL_FREEZE_DURATION');
  static const MetricLabel CLIENT_VIDEO_SUBSCRIBER_PAUSE_COUNT =
      MetricLabel._(5, _omitEnumNames ? '' : 'CLIENT_VIDEO_SUBSCRIBER_PAUSE_COUNT');
  static const MetricLabel CLIENT_VIDEO_SUBSCRIBER_TOTAL_PAUSES_DURATION =
      MetricLabel._(6, _omitEnumNames ? '' : 'CLIENT_VIDEO_SUBSCRIBER_TOTAL_PAUSES_DURATION');
  static const MetricLabel CLIENT_AUDIO_SUBSCRIBER_CONCEALED_SAMPLES =
      MetricLabel._(7, _omitEnumNames ? '' : 'CLIENT_AUDIO_SUBSCRIBER_CONCEALED_SAMPLES');
  static const MetricLabel CLIENT_AUDIO_SUBSCRIBER_SILENT_CONCEALED_SAMPLES =
      MetricLabel._(8, _omitEnumNames ? '' : 'CLIENT_AUDIO_SUBSCRIBER_SILENT_CONCEALED_SAMPLES');
  static const MetricLabel CLIENT_AUDIO_SUBSCRIBER_CONCEALMENT_EVENTS =
      MetricLabel._(9, _omitEnumNames ? '' : 'CLIENT_AUDIO_SUBSCRIBER_CONCEALMENT_EVENTS');
  static const MetricLabel CLIENT_AUDIO_SUBSCRIBER_INTERRUPTION_COUNT =
      MetricLabel._(10, _omitEnumNames ? '' : 'CLIENT_AUDIO_SUBSCRIBER_INTERRUPTION_COUNT');
  static const MetricLabel CLIENT_AUDIO_SUBSCRIBER_TOTAL_INTERRUPTION_DURATION =
      MetricLabel._(11, _omitEnumNames ? '' : 'CLIENT_AUDIO_SUBSCRIBER_TOTAL_INTERRUPTION_DURATION');
  static const MetricLabel CLIENT_SUBSCRIBER_JITTER_BUFFER_DELAY =
      MetricLabel._(12, _omitEnumNames ? '' : 'CLIENT_SUBSCRIBER_JITTER_BUFFER_DELAY');
  static const MetricLabel CLIENT_SUBSCRIBER_JITTER_BUFFER_EMITTED_COUNT =
      MetricLabel._(13, _omitEnumNames ? '' : 'CLIENT_SUBSCRIBER_JITTER_BUFFER_EMITTED_COUNT');
  static const MetricLabel CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_BANDWIDTH =
      MetricLabel._(14, _omitEnumNames ? '' : 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_BANDWIDTH');
  static const MetricLabel CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_CPU =
      MetricLabel._(15, _omitEnumNames ? '' : 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_CPU');
  static const MetricLabel CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_OTHER =
      MetricLabel._(16, _omitEnumNames ? '' : 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_OTHER');
  static const MetricLabel PUBLISHER_RTT = MetricLabel._(17, _omitEnumNames ? '' : 'PUBLISHER_RTT');
  static const MetricLabel SERVER_MESH_RTT = MetricLabel._(18, _omitEnumNames ? '' : 'SERVER_MESH_RTT');
  static const MetricLabel SUBSCRIBER_RTT = MetricLabel._(19, _omitEnumNames ? '' : 'SUBSCRIBER_RTT');
  static const MetricLabel METRIC_LABEL_PREDEFINED_MAX_VALUE =
      MetricLabel._(4096, _omitEnumNames ? '' : 'METRIC_LABEL_PREDEFINED_MAX_VALUE');

  static const $core.List<MetricLabel> values = <MetricLabel>[
    AGENTS_LLM_TTFT,
    AGENTS_STT_TTFT,
    AGENTS_TTS_TTFB,
    CLIENT_VIDEO_SUBSCRIBER_FREEZE_COUNT,
    CLIENT_VIDEO_SUBSCRIBER_TOTAL_FREEZE_DURATION,
    CLIENT_VIDEO_SUBSCRIBER_PAUSE_COUNT,
    CLIENT_VIDEO_SUBSCRIBER_TOTAL_PAUSES_DURATION,
    CLIENT_AUDIO_SUBSCRIBER_CONCEALED_SAMPLES,
    CLIENT_AUDIO_SUBSCRIBER_SILENT_CONCEALED_SAMPLES,
    CLIENT_AUDIO_SUBSCRIBER_CONCEALMENT_EVENTS,
    CLIENT_AUDIO_SUBSCRIBER_INTERRUPTION_COUNT,
    CLIENT_AUDIO_SUBSCRIBER_TOTAL_INTERRUPTION_DURATION,
    CLIENT_SUBSCRIBER_JITTER_BUFFER_DELAY,
    CLIENT_SUBSCRIBER_JITTER_BUFFER_EMITTED_COUNT,
    CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_BANDWIDTH,
    CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_CPU,
    CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_OTHER,
    PUBLISHER_RTT,
    SERVER_MESH_RTT,
    SUBSCRIBER_RTT,
    METRIC_LABEL_PREDEFINED_MAX_VALUE,
  ];

  static final $core.Map<$core.int, MetricLabel> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MetricLabel? valueOf($core.int value) => _byValue[value];

  const MetricLabel._(super.value, super.name);
}

const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
