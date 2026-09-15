// This is a generated file - do not edit.
//
// Generated from livekit_metrics.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use metricLabelDescriptor instead')
const MetricLabel$json = {
  '1': 'MetricLabel',
  '2': [
    {'1': 'AGENTS_LLM_TTFT', '2': 0},
    {'1': 'AGENTS_STT_TTFT', '2': 1},
    {'1': 'AGENTS_TTS_TTFB', '2': 2},
    {'1': 'CLIENT_VIDEO_SUBSCRIBER_FREEZE_COUNT', '2': 3},
    {'1': 'CLIENT_VIDEO_SUBSCRIBER_TOTAL_FREEZE_DURATION', '2': 4},
    {'1': 'CLIENT_VIDEO_SUBSCRIBER_PAUSE_COUNT', '2': 5},
    {'1': 'CLIENT_VIDEO_SUBSCRIBER_TOTAL_PAUSES_DURATION', '2': 6},
    {'1': 'CLIENT_AUDIO_SUBSCRIBER_CONCEALED_SAMPLES', '2': 7},
    {'1': 'CLIENT_AUDIO_SUBSCRIBER_SILENT_CONCEALED_SAMPLES', '2': 8},
    {'1': 'CLIENT_AUDIO_SUBSCRIBER_CONCEALMENT_EVENTS', '2': 9},
    {'1': 'CLIENT_AUDIO_SUBSCRIBER_INTERRUPTION_COUNT', '2': 10},
    {'1': 'CLIENT_AUDIO_SUBSCRIBER_TOTAL_INTERRUPTION_DURATION', '2': 11},
    {'1': 'CLIENT_SUBSCRIBER_JITTER_BUFFER_DELAY', '2': 12},
    {'1': 'CLIENT_SUBSCRIBER_JITTER_BUFFER_EMITTED_COUNT', '2': 13},
    {'1': 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_BANDWIDTH', '2': 14},
    {'1': 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_CPU', '2': 15},
    {'1': 'CLIENT_VIDEO_PUBLISHER_QUALITY_LIMITATION_DURATION_OTHER', '2': 16},
    {'1': 'PUBLISHER_RTT', '2': 17},
    {'1': 'SERVER_MESH_RTT', '2': 18},
    {'1': 'SUBSCRIBER_RTT', '2': 19},
    {'1': 'METRIC_LABEL_PREDEFINED_MAX_VALUE', '2': 4096},
  ],
};

/// Descriptor for `MetricLabel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List metricLabelDescriptor =
    $convert.base64Decode('CgtNZXRyaWNMYWJlbBITCg9BR0VOVFNfTExNX1RURlQQABITCg9BR0VOVFNfU1RUX1RURlQQAR'
        'ITCg9BR0VOVFNfVFRTX1RURkIQAhIoCiRDTElFTlRfVklERU9fU1VCU0NSSUJFUl9GUkVFWkVf'
        'Q09VTlQQAxIxCi1DTElFTlRfVklERU9fU1VCU0NSSUJFUl9UT1RBTF9GUkVFWkVfRFVSQVRJT0'
        '4QBBInCiNDTElFTlRfVklERU9fU1VCU0NSSUJFUl9QQVVTRV9DT1VOVBAFEjEKLUNMSUVOVF9W'
        'SURFT19TVUJTQ1JJQkVSX1RPVEFMX1BBVVNFU19EVVJBVElPThAGEi0KKUNMSUVOVF9BVURJT1'
        '9TVUJTQ1JJQkVSX0NPTkNFQUxFRF9TQU1QTEVTEAcSNAowQ0xJRU5UX0FVRElPX1NVQlNDUklC'
        'RVJfU0lMRU5UX0NPTkNFQUxFRF9TQU1QTEVTEAgSLgoqQ0xJRU5UX0FVRElPX1NVQlNDUklCRV'
        'JfQ09OQ0VBTE1FTlRfRVZFTlRTEAkSLgoqQ0xJRU5UX0FVRElPX1NVQlNDUklCRVJfSU5URVJS'
        'VVBUSU9OX0NPVU5UEAoSNwozQ0xJRU5UX0FVRElPX1NVQlNDUklCRVJfVE9UQUxfSU5URVJSVV'
        'BUSU9OX0RVUkFUSU9OEAsSKQolQ0xJRU5UX1NVQlNDUklCRVJfSklUVEVSX0JVRkZFUl9ERUxB'
        'WRAMEjEKLUNMSUVOVF9TVUJTQ1JJQkVSX0pJVFRFUl9CVUZGRVJfRU1JVFRFRF9DT1VOVBANEk'
        'AKPENMSUVOVF9WSURFT19QVUJMSVNIRVJfUVVBTElUWV9MSU1JVEFUSU9OX0RVUkFUSU9OX0JB'
        'TkRXSURUSBAOEjoKNkNMSUVOVF9WSURFT19QVUJMSVNIRVJfUVVBTElUWV9MSU1JVEFUSU9OX0'
        'RVUkFUSU9OX0NQVRAPEjwKOENMSUVOVF9WSURFT19QVUJMSVNIRVJfUVVBTElUWV9MSU1JVEFU'
        'SU9OX0RVUkFUSU9OX09USEVSEBASEQoNUFVCTElTSEVSX1JUVBAREhMKD1NFUlZFUl9NRVNIX1'
        'JUVBASEhIKDlNVQlNDUklCRVJfUlRUEBMSJgohTUVUUklDX0xBQkVMX1BSRURFRklORURfTUFY'
        'X1ZBTFVFEIAg');

@$core.Deprecated('Use metricsBatchDescriptor instead')
const MetricsBatch$json = {
  '1': 'MetricsBatch',
  '2': [
    {'1': 'timestamp_ms', '3': 1, '4': 1, '5': 3, '10': 'timestampMs'},
    {
      '1': 'normalized_timestamp',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'normalizedTimestamp'
    },
    {'1': 'str_data', '3': 3, '4': 3, '5': 9, '10': 'strData'},
    {'1': 'time_series', '3': 4, '4': 3, '5': 11, '6': '.livekit.TimeSeriesMetric', '10': 'timeSeries'},
    {'1': 'events', '3': 5, '4': 3, '5': 11, '6': '.livekit.EventMetric', '10': 'events'},
  ],
};

/// Descriptor for `MetricsBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metricsBatchDescriptor =
    $convert.base64Decode('CgxNZXRyaWNzQmF0Y2gSIQoMdGltZXN0YW1wX21zGAEgASgDUgt0aW1lc3RhbXBNcxJNChRub3'
        'JtYWxpemVkX3RpbWVzdGFtcBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSE25v'
        'cm1hbGl6ZWRUaW1lc3RhbXASGQoIc3RyX2RhdGEYAyADKAlSB3N0ckRhdGESOgoLdGltZV9zZX'
        'JpZXMYBCADKAsyGS5saXZla2l0LlRpbWVTZXJpZXNNZXRyaWNSCnRpbWVTZXJpZXMSLAoGZXZl'
        'bnRzGAUgAygLMhQubGl2ZWtpdC5FdmVudE1ldHJpY1IGZXZlbnRz');

@$core.Deprecated('Use timeSeriesMetricDescriptor instead')
const TimeSeriesMetric$json = {
  '1': 'TimeSeriesMetric',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 13, '10': 'label'},
    {'1': 'participant_identity', '3': 2, '4': 1, '5': 13, '10': 'participantIdentity'},
    {'1': 'track_sid', '3': 3, '4': 1, '5': 13, '10': 'trackSid'},
    {'1': 'samples', '3': 4, '4': 3, '5': 11, '6': '.livekit.MetricSample', '10': 'samples'},
    {'1': 'rid', '3': 5, '4': 1, '5': 13, '10': 'rid'},
  ],
};

/// Descriptor for `TimeSeriesMetric`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeSeriesMetricDescriptor =
    $convert.base64Decode('ChBUaW1lU2VyaWVzTWV0cmljEhQKBWxhYmVsGAEgASgNUgVsYWJlbBIxChRwYXJ0aWNpcGFudF'
        '9pZGVudGl0eRgCIAEoDVITcGFydGljaXBhbnRJZGVudGl0eRIbCgl0cmFja19zaWQYAyABKA1S'
        'CHRyYWNrU2lkEi8KB3NhbXBsZXMYBCADKAsyFS5saXZla2l0Lk1ldHJpY1NhbXBsZVIHc2FtcG'
        'xlcxIQCgNyaWQYBSABKA1SA3JpZA==');

@$core.Deprecated('Use metricSampleDescriptor instead')
const MetricSample$json = {
  '1': 'MetricSample',
  '2': [
    {'1': 'timestamp_ms', '3': 1, '4': 1, '5': 3, '10': 'timestampMs'},
    {
      '1': 'normalized_timestamp',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'normalizedTimestamp'
    },
    {'1': 'value', '3': 3, '4': 1, '5': 2, '10': 'value'},
  ],
};

/// Descriptor for `MetricSample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metricSampleDescriptor =
    $convert.base64Decode('CgxNZXRyaWNTYW1wbGUSIQoMdGltZXN0YW1wX21zGAEgASgDUgt0aW1lc3RhbXBNcxJNChRub3'
        'JtYWxpemVkX3RpbWVzdGFtcBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSE25v'
        'cm1hbGl6ZWRUaW1lc3RhbXASFAoFdmFsdWUYAyABKAJSBXZhbHVl');

@$core.Deprecated('Use eventMetricDescriptor instead')
const EventMetric$json = {
  '1': 'EventMetric',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 13, '10': 'label'},
    {'1': 'participant_identity', '3': 2, '4': 1, '5': 13, '10': 'participantIdentity'},
    {'1': 'track_sid', '3': 3, '4': 1, '5': 13, '10': 'trackSid'},
    {'1': 'start_timestamp_ms', '3': 4, '4': 1, '5': 3, '10': 'startTimestampMs'},
    {'1': 'end_timestamp_ms', '3': 5, '4': 1, '5': 3, '9': 0, '10': 'endTimestampMs', '17': true},
    {
      '1': 'normalized_start_timestamp',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'normalizedStartTimestamp'
    },
    {
      '1': 'normalized_end_timestamp',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '9': 1,
      '10': 'normalizedEndTimestamp',
      '17': true
    },
    {'1': 'metadata', '3': 8, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'rid', '3': 9, '4': 1, '5': 13, '10': 'rid'},
  ],
  '8': [
    {'1': '_end_timestamp_ms'},
    {'1': '_normalized_end_timestamp'},
  ],
};

/// Descriptor for `EventMetric`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventMetricDescriptor =
    $convert.base64Decode('CgtFdmVudE1ldHJpYxIUCgVsYWJlbBgBIAEoDVIFbGFiZWwSMQoUcGFydGljaXBhbnRfaWRlbn'
        'RpdHkYAiABKA1SE3BhcnRpY2lwYW50SWRlbnRpdHkSGwoJdHJhY2tfc2lkGAMgASgNUgh0cmFj'
        'a1NpZBIsChJzdGFydF90aW1lc3RhbXBfbXMYBCABKANSEHN0YXJ0VGltZXN0YW1wTXMSLQoQZW'
        '5kX3RpbWVzdGFtcF9tcxgFIAEoA0gAUg5lbmRUaW1lc3RhbXBNc4gBARJYChpub3JtYWxpemVk'
        'X3N0YXJ0X3RpbWVzdGFtcBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSGG5vcm'
        '1hbGl6ZWRTdGFydFRpbWVzdGFtcBJZChhub3JtYWxpemVkX2VuZF90aW1lc3RhbXAYByABKAsy'
        'Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAFSFm5vcm1hbGl6ZWRFbmRUaW1lc3RhbXCIAQ'
        'ESGgoIbWV0YWRhdGEYCCABKAlSCG1ldGFkYXRhEhAKA3JpZBgJIAEoDVIDcmlkQhMKEV9lbmRf'
        'dGltZXN0YW1wX21zQhsKGV9ub3JtYWxpemVkX2VuZF90aW1lc3RhbXA=');

@$core.Deprecated('Use metricsRecordingHeaderDescriptor instead')
const MetricsRecordingHeader$json = {
  '1': 'MetricsRecordingHeader',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'duration', '3': 3, '4': 1, '5': 4, '10': 'duration'},
    {'1': 'start_time', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    {'1': 'room_tags', '3': 5, '4': 3, '5': 11, '6': '.livekit.MetricsRecordingHeader.RoomTagsEntry', '10': 'roomTags'},
  ],
  '3': [MetricsRecordingHeader_RoomTagsEntry$json],
};

@$core.Deprecated('Use metricsRecordingHeaderDescriptor instead')
const MetricsRecordingHeader_RoomTagsEntry$json = {
  '1': 'RoomTagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `MetricsRecordingHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metricsRecordingHeaderDescriptor =
    $convert.base64Decode('ChZNZXRyaWNzUmVjb3JkaW5nSGVhZGVyEhcKB3Jvb21faWQYASABKAlSBnJvb21JZBIaCghkdX'
        'JhdGlvbhgDIAEoBFIIZHVyYXRpb24SOQoKc3RhcnRfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90'
        'b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRJKCglyb29tX3RhZ3MYBSADKAsyLS5saXZla2l0Lk'
        '1ldHJpY3NSZWNvcmRpbmdIZWFkZXIuUm9vbVRhZ3NFbnRyeVIIcm9vbVRhZ3MaOwoNUm9vbVRh'
        'Z3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');
