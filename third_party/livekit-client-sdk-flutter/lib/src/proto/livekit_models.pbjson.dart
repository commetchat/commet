// This is a generated file - do not edit.
//
// Generated from livekit_models.proto.

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

@$core.Deprecated('Use audioCodecDescriptor instead')
const AudioCodec$json = {
  '1': 'AudioCodec',
  '2': [
    {'1': 'DEFAULT_AC', '2': 0},
    {'1': 'OPUS', '2': 1},
    {'1': 'AAC', '2': 2},
    {'1': 'AC_MP3', '2': 3},
  ],
};

/// Descriptor for `AudioCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioCodecDescriptor =
    $convert.base64Decode('CgpBdWRpb0NvZGVjEg4KCkRFRkFVTFRfQUMQABIICgRPUFVTEAESBwoDQUFDEAISCgoGQUNfTV'
        'AzEAM=');

@$core.Deprecated('Use videoCodecDescriptor instead')
const VideoCodec$json = {
  '1': 'VideoCodec',
  '2': [
    {'1': 'DEFAULT_VC', '2': 0},
    {'1': 'H264_BASELINE', '2': 1},
    {'1': 'H264_MAIN', '2': 2},
    {'1': 'H264_HIGH', '2': 3},
    {'1': 'VP8', '2': 4},
  ],
};

/// Descriptor for `VideoCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoCodecDescriptor =
    $convert.base64Decode('CgpWaWRlb0NvZGVjEg4KCkRFRkFVTFRfVkMQABIRCg1IMjY0X0JBU0VMSU5FEAESDQoJSDI2NF'
        '9NQUlOEAISDQoJSDI2NF9ISUdIEAMSBwoDVlA4EAQ=');

@$core.Deprecated('Use imageCodecDescriptor instead')
const ImageCodec$json = {
  '1': 'ImageCodec',
  '2': [
    {'1': 'IC_DEFAULT', '2': 0},
    {'1': 'IC_JPEG', '2': 1},
  ],
};

/// Descriptor for `ImageCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List imageCodecDescriptor =
    $convert.base64Decode('CgpJbWFnZUNvZGVjEg4KCklDX0RFRkFVTFQQABILCgdJQ19KUEVHEAE=');

@$core.Deprecated('Use backupCodecPolicyDescriptor instead')
const BackupCodecPolicy$json = {
  '1': 'BackupCodecPolicy',
  '2': [
    {'1': 'PREFER_REGRESSION', '2': 0},
    {'1': 'SIMULCAST', '2': 1},
    {'1': 'REGRESSION', '2': 2},
  ],
};

/// Descriptor for `BackupCodecPolicy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List backupCodecPolicyDescriptor =
    $convert.base64Decode('ChFCYWNrdXBDb2RlY1BvbGljeRIVChFQUkVGRVJfUkVHUkVTU0lPThAAEg0KCVNJTVVMQ0FTVB'
        'ABEg4KClJFR1JFU1NJT04QAg==');

@$core.Deprecated('Use trackTypeDescriptor instead')
const TrackType$json = {
  '1': 'TrackType',
  '2': [
    {'1': 'AUDIO', '2': 0},
    {'1': 'VIDEO', '2': 1},
    {'1': 'DATA', '2': 2},
  ],
};

/// Descriptor for `TrackType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackTypeDescriptor =
    $convert.base64Decode('CglUcmFja1R5cGUSCQoFQVVESU8QABIJCgVWSURFTxABEggKBERBVEEQAg==');

@$core.Deprecated('Use trackSourceDescriptor instead')
const TrackSource$json = {
  '1': 'TrackSource',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'CAMERA', '2': 1},
    {'1': 'MICROPHONE', '2': 2},
    {'1': 'SCREEN_SHARE', '2': 3},
    {'1': 'SCREEN_SHARE_AUDIO', '2': 4},
  ],
};

/// Descriptor for `TrackSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackSourceDescriptor =
    $convert.base64Decode('CgtUcmFja1NvdXJjZRILCgdVTktOT1dOEAASCgoGQ0FNRVJBEAESDgoKTUlDUk9QSE9ORRACEh'
        'AKDFNDUkVFTl9TSEFSRRADEhYKElNDUkVFTl9TSEFSRV9BVURJTxAE');

@$core.Deprecated('Use dataTrackExtensionIDDescriptor instead')
const DataTrackExtensionID$json = {
  '1': 'DataTrackExtensionID',
  '2': [
    {'1': 'DTEI_INVALID', '2': 0},
    {'1': 'DTEI_PARTICIPANT_SID', '2': 1},
  ],
};

/// Descriptor for `DataTrackExtensionID`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dataTrackExtensionIDDescriptor =
    $convert.base64Decode('ChREYXRhVHJhY2tFeHRlbnNpb25JRBIQCgxEVEVJX0lOVkFMSUQQABIYChREVEVJX1BBUlRJQ0'
        'lQQU5UX1NJRBAB');

@$core.Deprecated('Use videoQualityDescriptor instead')
const VideoQuality$json = {
  '1': 'VideoQuality',
  '2': [
    {'1': 'LOW', '2': 0},
    {'1': 'MEDIUM', '2': 1},
    {'1': 'HIGH', '2': 2},
    {'1': 'OFF', '2': 3},
  ],
};

/// Descriptor for `VideoQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoQualityDescriptor =
    $convert.base64Decode('CgxWaWRlb1F1YWxpdHkSBwoDTE9XEAASCgoGTUVESVVNEAESCAoESElHSBACEgcKA09GRhAD');

@$core.Deprecated('Use connectionQualityDescriptor instead')
const ConnectionQuality$json = {
  '1': 'ConnectionQuality',
  '2': [
    {'1': 'POOR', '2': 0},
    {'1': 'GOOD', '2': 1},
    {'1': 'EXCELLENT', '2': 2},
    {'1': 'LOST', '2': 3},
  ],
};

/// Descriptor for `ConnectionQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionQualityDescriptor =
    $convert.base64Decode('ChFDb25uZWN0aW9uUXVhbGl0eRIICgRQT09SEAASCAoER09PRBABEg0KCUVYQ0VMTEVOVBACEg'
        'gKBExPU1QQAw==');

@$core.Deprecated('Use clientConfigSettingDescriptor instead')
const ClientConfigSetting$json = {
  '1': 'ClientConfigSetting',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'DISABLED', '2': 1},
    {'1': 'ENABLED', '2': 2},
  ],
};

/// Descriptor for `ClientConfigSetting`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List clientConfigSettingDescriptor =
    $convert.base64Decode('ChNDbGllbnRDb25maWdTZXR0aW5nEgkKBVVOU0VUEAASDAoIRElTQUJMRUQQARILCgdFTkFCTE'
        'VEEAI=');

@$core.Deprecated('Use disconnectReasonDescriptor instead')
const DisconnectReason$json = {
  '1': 'DisconnectReason',
  '2': [
    {'1': 'UNKNOWN_REASON', '2': 0},
    {'1': 'CLIENT_INITIATED', '2': 1},
    {'1': 'DUPLICATE_IDENTITY', '2': 2},
    {'1': 'SERVER_SHUTDOWN', '2': 3},
    {'1': 'PARTICIPANT_REMOVED', '2': 4},
    {'1': 'ROOM_DELETED', '2': 5},
    {'1': 'STATE_MISMATCH', '2': 6},
    {'1': 'JOIN_FAILURE', '2': 7},
    {'1': 'MIGRATION', '2': 8},
    {'1': 'SIGNAL_CLOSE', '2': 9},
    {'1': 'ROOM_CLOSED', '2': 10},
    {'1': 'USER_UNAVAILABLE', '2': 11},
    {'1': 'USER_REJECTED', '2': 12},
    {'1': 'SIP_TRUNK_FAILURE', '2': 13},
    {'1': 'CONNECTION_TIMEOUT', '2': 14},
    {'1': 'MEDIA_FAILURE', '2': 15},
  ],
};

/// Descriptor for `DisconnectReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List disconnectReasonDescriptor =
    $convert.base64Decode('ChBEaXNjb25uZWN0UmVhc29uEhIKDlVOS05PV05fUkVBU09OEAASFAoQQ0xJRU5UX0lOSVRJQV'
        'RFRBABEhYKEkRVUExJQ0FURV9JREVOVElUWRACEhMKD1NFUlZFUl9TSFVURE9XThADEhcKE1BB'
        'UlRJQ0lQQU5UX1JFTU9WRUQQBBIQCgxST09NX0RFTEVURUQQBRISCg5TVEFURV9NSVNNQVRDSB'
        'AGEhAKDEpPSU5fRkFJTFVSRRAHEg0KCU1JR1JBVElPThAIEhAKDFNJR05BTF9DTE9TRRAJEg8K'
        'C1JPT01fQ0xPU0VEEAoSFAoQVVNFUl9VTkFWQUlMQUJMRRALEhEKDVVTRVJfUkVKRUNURUQQDB'
        'IVChFTSVBfVFJVTktfRkFJTFVSRRANEhYKEkNPTk5FQ1RJT05fVElNRU9VVBAOEhEKDU1FRElB'
        'X0ZBSUxVUkUQDw==');

@$core.Deprecated('Use reconnectReasonDescriptor instead')
const ReconnectReason$json = {
  '1': 'ReconnectReason',
  '2': [
    {'1': 'RR_UNKNOWN', '2': 0},
    {'1': 'RR_SIGNAL_DISCONNECTED', '2': 1},
    {'1': 'RR_PUBLISHER_FAILED', '2': 2},
    {'1': 'RR_SUBSCRIBER_FAILED', '2': 3},
    {'1': 'RR_SWITCH_CANDIDATE', '2': 4},
  ],
};

/// Descriptor for `ReconnectReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List reconnectReasonDescriptor =
    $convert.base64Decode('Cg9SZWNvbm5lY3RSZWFzb24SDgoKUlJfVU5LTk9XThAAEhoKFlJSX1NJR05BTF9ESVNDT05ORU'
        'NURUQQARIXChNSUl9QVUJMSVNIRVJfRkFJTEVEEAISGAoUUlJfU1VCU0NSSUJFUl9GQUlMRUQQ'
        'AxIXChNSUl9TV0lUQ0hfQ0FORElEQVRFEAQ=');

@$core.Deprecated('Use subscriptionErrorDescriptor instead')
const SubscriptionError$json = {
  '1': 'SubscriptionError',
  '2': [
    {'1': 'SE_UNKNOWN', '2': 0},
    {'1': 'SE_CODEC_UNSUPPORTED', '2': 1},
    {'1': 'SE_TRACK_NOTFOUND', '2': 2},
  ],
};

/// Descriptor for `SubscriptionError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List subscriptionErrorDescriptor =
    $convert.base64Decode('ChFTdWJzY3JpcHRpb25FcnJvchIOCgpTRV9VTktOT1dOEAASGAoUU0VfQ09ERUNfVU5TVVBQT1'
        'JURUQQARIVChFTRV9UUkFDS19OT1RGT1VORBAC');

@$core.Deprecated('Use audioTrackFeatureDescriptor instead')
const AudioTrackFeature$json = {
  '1': 'AudioTrackFeature',
  '2': [
    {'1': 'TF_STEREO', '2': 0},
    {'1': 'TF_NO_DTX', '2': 1},
    {'1': 'TF_AUTO_GAIN_CONTROL', '2': 2},
    {'1': 'TF_ECHO_CANCELLATION', '2': 3},
    {'1': 'TF_NOISE_SUPPRESSION', '2': 4},
    {'1': 'TF_ENHANCED_NOISE_CANCELLATION', '2': 5},
    {'1': 'TF_PRECONNECT_BUFFER', '2': 6},
  ],
};

/// Descriptor for `AudioTrackFeature`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioTrackFeatureDescriptor =
    $convert.base64Decode('ChFBdWRpb1RyYWNrRmVhdHVyZRINCglURl9TVEVSRU8QABINCglURl9OT19EVFgQARIYChRURl'
        '9BVVRPX0dBSU5fQ09OVFJPTBACEhgKFFRGX0VDSE9fQ0FOQ0VMTEFUSU9OEAMSGAoUVEZfTk9J'
        'U0VfU1VQUFJFU1NJT04QBBIiCh5URl9FTkhBTkNFRF9OT0lTRV9DQU5DRUxMQVRJT04QBRIYCh'
        'RURl9QUkVDT05ORUNUX0JVRkZFUhAG');

@$core.Deprecated('Use paginationDescriptor instead')
const Pagination$json = {
  '1': 'Pagination',
  '2': [
    {'1': 'after_id', '3': 1, '4': 1, '5': 9, '10': 'afterId'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `Pagination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List paginationDescriptor =
    $convert.base64Decode('CgpQYWdpbmF0aW9uEhkKCGFmdGVyX2lkGAEgASgJUgdhZnRlcklkEhQKBWxpbWl0GAIgASgFUg'
        'VsaW1pdA==');

@$core.Deprecated('Use tokenPaginationDescriptor instead')
const TokenPagination$json = {
  '1': 'TokenPagination',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `TokenPagination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenPaginationDescriptor =
    $convert.base64Decode('Cg9Ub2tlblBhZ2luYXRpb24SFAoFdG9rZW4YASABKAlSBXRva2Vu');

@$core.Deprecated('Use listUpdateDescriptor instead')
const ListUpdate$json = {
  '1': 'ListUpdate',
  '2': [
    {'1': 'set', '3': 1, '4': 3, '5': 9, '10': 'set'},
    {'1': 'add', '3': 2, '4': 3, '5': 9, '10': 'add'},
    {'1': 'remove', '3': 3, '4': 3, '5': 9, '10': 'remove'},
    {'1': 'clear', '3': 4, '4': 1, '5': 8, '10': 'clear'},
  ],
};

/// Descriptor for `ListUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listUpdateDescriptor =
    $convert.base64Decode('CgpMaXN0VXBkYXRlEhAKA3NldBgBIAMoCVIDc2V0EhAKA2FkZBgCIAMoCVIDYWRkEhYKBnJlbW'
        '92ZRgDIAMoCVIGcmVtb3ZlEhQKBWNsZWFyGAQgASgIUgVjbGVhcg==');

@$core.Deprecated('Use roomDescriptor instead')
const Room$json = {
  '1': 'Room',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'empty_timeout', '3': 3, '4': 1, '5': 13, '10': 'emptyTimeout'},
    {'1': 'departure_timeout', '3': 14, '4': 1, '5': 13, '10': 'departureTimeout'},
    {'1': 'max_participants', '3': 4, '4': 1, '5': 13, '10': 'maxParticipants'},
    {'1': 'creation_time', '3': 5, '4': 1, '5': 3, '10': 'creationTime'},
    {'1': 'creation_time_ms', '3': 15, '4': 1, '5': 3, '10': 'creationTimeMs'},
    {'1': 'turn_password', '3': 6, '4': 1, '5': 9, '10': 'turnPassword'},
    {'1': 'enabled_codecs', '3': 7, '4': 3, '5': 11, '6': '.livekit.Codec', '10': 'enabledCodecs'},
    {'1': 'metadata', '3': 8, '4': 1, '5': 9, '8': {}, '10': 'metadata'},
    {'1': 'num_participants', '3': 9, '4': 1, '5': 13, '10': 'numParticipants'},
    {'1': 'num_publishers', '3': 11, '4': 1, '5': 13, '10': 'numPublishers'},
    {'1': 'active_recording', '3': 10, '4': 1, '5': 8, '10': 'activeRecording'},
    {'1': 'version', '3': 13, '4': 1, '5': 11, '6': '.livekit.TimedVersion', '10': 'version'},
  ],
};

/// Descriptor for `Room`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomDescriptor =
    $convert.base64Decode('CgRSb29tEhAKA3NpZBgBIAEoCVIDc2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNZW1wdHlfdG'
        'ltZW91dBgDIAEoDVIMZW1wdHlUaW1lb3V0EisKEWRlcGFydHVyZV90aW1lb3V0GA4gASgNUhBk'
        'ZXBhcnR1cmVUaW1lb3V0EikKEG1heF9wYXJ0aWNpcGFudHMYBCABKA1SD21heFBhcnRpY2lwYW'
        '50cxIjCg1jcmVhdGlvbl90aW1lGAUgASgDUgxjcmVhdGlvblRpbWUSKAoQY3JlYXRpb25fdGlt'
        'ZV9tcxgPIAEoA1IOY3JlYXRpb25UaW1lTXMSIwoNdHVybl9wYXNzd29yZBgGIAEoCVIMdHVybl'
        'Bhc3N3b3JkEjUKDmVuYWJsZWRfY29kZWNzGAcgAygLMg4ubGl2ZWtpdC5Db2RlY1INZW5hYmxl'
        'ZENvZGVjcxJCCghtZXRhZGF0YRgIIAEoCUImiOwsAZLsLB48cmVkYWN0ZWQgKHt7IC5TaXplIH'
        '19IGJ5dGVzKT5SCG1ldGFkYXRhEikKEG51bV9wYXJ0aWNpcGFudHMYCSABKA1SD251bVBhcnRp'
        'Y2lwYW50cxIlCg5udW1fcHVibGlzaGVycxgLIAEoDVINbnVtUHVibGlzaGVycxIpChBhY3Rpdm'
        'VfcmVjb3JkaW5nGAogASgIUg9hY3RpdmVSZWNvcmRpbmcSLwoHdmVyc2lvbhgNIAEoCzIVLmxp'
        'dmVraXQuVGltZWRWZXJzaW9uUgd2ZXJzaW9u');

@$core.Deprecated('Use codecDescriptor instead')
const Codec$json = {
  '1': 'Codec',
  '2': [
    {'1': 'mime', '3': 1, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'fmtp_line', '3': 2, '4': 1, '5': 9, '10': 'fmtpLine'},
  ],
};

/// Descriptor for `Codec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codecDescriptor =
    $convert.base64Decode('CgVDb2RlYxISCgRtaW1lGAEgASgJUgRtaW1lEhsKCWZtdHBfbGluZRgCIAEoCVIIZm10cExpbm'
        'U=');

@$core.Deprecated('Use playoutDelayDescriptor instead')
const PlayoutDelay$json = {
  '1': 'PlayoutDelay',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'min', '3': 2, '4': 1, '5': 13, '10': 'min'},
    {'1': 'max', '3': 3, '4': 1, '5': 13, '10': 'max'},
  ],
};

/// Descriptor for `PlayoutDelay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playoutDelayDescriptor =
    $convert.base64Decode('CgxQbGF5b3V0RGVsYXkSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIQCgNtaW4YAiABKA1SA2'
        '1pbhIQCgNtYXgYAyABKA1SA21heA==');

@$core.Deprecated('Use participantPermissionDescriptor instead')
const ParticipantPermission$json = {
  '1': 'ParticipantPermission',
  '2': [
    {'1': 'can_subscribe', '3': 1, '4': 1, '5': 8, '10': 'canSubscribe'},
    {'1': 'can_publish', '3': 2, '4': 1, '5': 8, '10': 'canPublish'},
    {'1': 'can_publish_data', '3': 3, '4': 1, '5': 8, '10': 'canPublishData'},
    {'1': 'can_publish_sources', '3': 9, '4': 3, '5': 14, '6': '.livekit.TrackSource', '10': 'canPublishSources'},
    {'1': 'hidden', '3': 7, '4': 1, '5': 8, '10': 'hidden'},
    {
      '1': 'recorder',
      '3': 8,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'recorder',
    },
    {'1': 'can_update_metadata', '3': 10, '4': 1, '5': 8, '10': 'canUpdateMetadata'},
    {
      '1': 'agent',
      '3': 11,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'agent',
    },
    {'1': 'can_subscribe_metrics', '3': 12, '4': 1, '5': 8, '10': 'canSubscribeMetrics'},
  ],
};

/// Descriptor for `ParticipantPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantPermissionDescriptor =
    $convert.base64Decode('ChVQYXJ0aWNpcGFudFBlcm1pc3Npb24SIwoNY2FuX3N1YnNjcmliZRgBIAEoCFIMY2FuU3Vic2'
        'NyaWJlEh8KC2Nhbl9wdWJsaXNoGAIgASgIUgpjYW5QdWJsaXNoEigKEGNhbl9wdWJsaXNoX2Rh'
        'dGEYAyABKAhSDmNhblB1Ymxpc2hEYXRhEkQKE2Nhbl9wdWJsaXNoX3NvdXJjZXMYCSADKA4yFC'
        '5saXZla2l0LlRyYWNrU291cmNlUhFjYW5QdWJsaXNoU291cmNlcxIWCgZoaWRkZW4YByABKAhS'
        'BmhpZGRlbhIeCghyZWNvcmRlchgIIAEoCEICGAFSCHJlY29yZGVyEi4KE2Nhbl91cGRhdGVfbW'
        'V0YWRhdGEYCiABKAhSEWNhblVwZGF0ZU1ldGFkYXRhEhgKBWFnZW50GAsgASgIQgIYAVIFYWdl'
        'bnQSMgoVY2FuX3N1YnNjcmliZV9tZXRyaWNzGAwgASgIUhNjYW5TdWJzY3JpYmVNZXRyaWNz');

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo$json = {
  '1': 'ParticipantInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'identity', '3': 2, '4': 1, '5': 9, '10': 'identity'},
    {'1': 'state', '3': 3, '4': 1, '5': 14, '6': '.livekit.ParticipantInfo.State', '10': 'state'},
    {'1': 'tracks', '3': 4, '4': 3, '5': 11, '6': '.livekit.TrackInfo', '10': 'tracks'},
    {'1': 'metadata', '3': 5, '4': 1, '5': 9, '8': {}, '10': 'metadata'},
    {'1': 'joined_at', '3': 6, '4': 1, '5': 3, '10': 'joinedAt'},
    {'1': 'joined_at_ms', '3': 17, '4': 1, '5': 3, '10': 'joinedAtMs'},
    {'1': 'name', '3': 9, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'version', '3': 10, '4': 1, '5': 13, '10': 'version'},
    {'1': 'permission', '3': 11, '4': 1, '5': 11, '6': '.livekit.ParticipantPermission', '10': 'permission'},
    {'1': 'region', '3': 12, '4': 1, '5': 9, '10': 'region'},
    {'1': 'is_publisher', '3': 13, '4': 1, '5': 8, '10': 'isPublisher'},
    {'1': 'kind', '3': 14, '4': 1, '5': 14, '6': '.livekit.ParticipantInfo.Kind', '10': 'kind'},
    {
      '1': 'attributes',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.livekit.ParticipantInfo.AttributesEntry',
      '8': {},
      '10': 'attributes'
    },
    {'1': 'disconnect_reason', '3': 16, '4': 1, '5': 14, '6': '.livekit.DisconnectReason', '10': 'disconnectReason'},
    {'1': 'kind_details', '3': 18, '4': 3, '5': 14, '6': '.livekit.ParticipantInfo.KindDetail', '10': 'kindDetails'},
    {'1': 'data_tracks', '3': 19, '4': 3, '5': 11, '6': '.livekit.DataTrackInfo', '10': 'dataTracks'},
  ],
  '3': [ParticipantInfo_AttributesEntry$json],
  '4': [ParticipantInfo_State$json, ParticipantInfo_Kind$json, ParticipantInfo_KindDetail$json],
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_AttributesEntry$json = {
  '1': 'AttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_State$json = {
  '1': 'State',
  '2': [
    {'1': 'JOINING', '2': 0},
    {'1': 'JOINED', '2': 1},
    {'1': 'ACTIVE', '2': 2},
    {'1': 'DISCONNECTED', '2': 3},
  ],
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'STANDARD', '2': 0},
    {'1': 'INGRESS', '2': 1},
    {'1': 'EGRESS', '2': 2},
    {'1': 'SIP', '2': 3},
    {'1': 'AGENT', '2': 4},
    {'1': 'CONNECTOR', '2': 7},
    {'1': 'BRIDGE', '2': 8},
  ],
};

@$core.Deprecated('Use participantInfoDescriptor instead')
const ParticipantInfo_KindDetail$json = {
  '1': 'KindDetail',
  '2': [
    {'1': 'CLOUD_AGENT', '2': 0},
    {'1': 'FORWARDED', '2': 1},
    {'1': 'CONNECTOR_WHATSAPP', '2': 2},
    {'1': 'CONNECTOR_TWILIO', '2': 3},
    {'1': 'BRIDGE_RTSP', '2': 4},
  ],
};

/// Descriptor for `ParticipantInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantInfoDescriptor =
    $convert.base64Decode('Cg9QYXJ0aWNpcGFudEluZm8SEAoDc2lkGAEgASgJUgNzaWQSGgoIaWRlbnRpdHkYAiABKAlSCG'
        'lkZW50aXR5EjQKBXN0YXRlGAMgASgOMh4ubGl2ZWtpdC5QYXJ0aWNpcGFudEluZm8uU3RhdGVS'
        'BXN0YXRlEioKBnRyYWNrcxgEIAMoCzISLmxpdmVraXQuVHJhY2tJbmZvUgZ0cmFja3MSQgoIbW'
        'V0YWRhdGEYBSABKAlCJojsLAGS7CwePHJlZGFjdGVkICh7eyAuU2l6ZSB9fSBieXRlcyk+Ught'
        'ZXRhZGF0YRIbCglqb2luZWRfYXQYBiABKANSCGpvaW5lZEF0EiAKDGpvaW5lZF9hdF9tcxgRIA'
        'EoA1IKam9pbmVkQXRNcxIYCgRuYW1lGAkgASgJQgSI7CwBUgRuYW1lEhgKB3ZlcnNpb24YCiAB'
        'KA1SB3ZlcnNpb24SPgoKcGVybWlzc2lvbhgLIAEoCzIeLmxpdmVraXQuUGFydGljaXBhbnRQZX'
        'JtaXNzaW9uUgpwZXJtaXNzaW9uEhYKBnJlZ2lvbhgMIAEoCVIGcmVnaW9uEiEKDGlzX3B1Ymxp'
        'c2hlchgNIAEoCFILaXNQdWJsaXNoZXISMQoEa2luZBgOIAEoDjIdLmxpdmVraXQuUGFydGljaX'
        'BhbnRJbmZvLktpbmRSBGtpbmQScAoKYXR0cmlidXRlcxgPIAMoCzIoLmxpdmVraXQuUGFydGlj'
        'aXBhbnRJbmZvLkF0dHJpYnV0ZXNFbnRyeUImiOwsAZLsLB48cmVkYWN0ZWQgKHt7IC5TaXplIH'
        '19IGJ5dGVzKT5SCmF0dHJpYnV0ZXMSRgoRZGlzY29ubmVjdF9yZWFzb24YECABKA4yGS5saXZl'
        'a2l0LkRpc2Nvbm5lY3RSZWFzb25SEGRpc2Nvbm5lY3RSZWFzb24SRgoMa2luZF9kZXRhaWxzGB'
        'IgAygOMiMubGl2ZWtpdC5QYXJ0aWNpcGFudEluZm8uS2luZERldGFpbFILa2luZERldGFpbHMS'
        'NwoLZGF0YV90cmFja3MYEyADKAsyFi5saXZla2l0LkRhdGFUcmFja0luZm9SCmRhdGFUcmFja3'
        'MaPQoPQXR0cmlidXRlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2'
        'YWx1ZToCOAEiPgoFU3RhdGUSCwoHSk9JTklORxAAEgoKBkpPSU5FRBABEgoKBkFDVElWRRACEh'
        'AKDERJU0NPTk5FQ1RFRBADIlwKBEtpbmQSDAoIU1RBTkRBUkQQABILCgdJTkdSRVNTEAESCgoG'
        'RUdSRVNTEAISBwoDU0lQEAMSCQoFQUdFTlQQBBINCglDT05ORUNUT1IQBxIKCgZCUklER0UQCC'
        'JrCgpLaW5kRGV0YWlsEg8KC0NMT1VEX0FHRU5UEAASDQoJRk9SV0FSREVEEAESFgoSQ09OTkVD'
        'VE9SX1dIQVRTQVBQEAISFAoQQ09OTkVDVE9SX1RXSUxJTxADEg8KC0JSSURHRV9SVFNQEAQ=');

@$core.Deprecated('Use encryptionDescriptor instead')
const Encryption$json = {
  '1': 'Encryption',
  '4': [Encryption_Type$json],
};

@$core.Deprecated('Use encryptionDescriptor instead')
const Encryption_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'GCM', '2': 1},
    {'1': 'CUSTOM', '2': 2},
  ],
};

/// Descriptor for `Encryption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptionDescriptor =
    $convert.base64Decode('CgpFbmNyeXB0aW9uIiUKBFR5cGUSCAoETk9ORRAAEgcKA0dDTRABEgoKBkNVU1RPTRAC');

@$core.Deprecated('Use simulcastCodecInfoDescriptor instead')
const SimulcastCodecInfo$json = {
  '1': 'SimulcastCodecInfo',
  '2': [
    {'1': 'mime_type', '3': 1, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'mid', '3': 2, '4': 1, '5': 9, '10': 'mid'},
    {'1': 'cid', '3': 3, '4': 1, '5': 9, '10': 'cid'},
    {'1': 'layers', '3': 4, '4': 3, '5': 11, '6': '.livekit.VideoLayer', '10': 'layers'},
    {'1': 'video_layer_mode', '3': 5, '4': 1, '5': 14, '6': '.livekit.VideoLayer.Mode', '10': 'videoLayerMode'},
    {'1': 'sdp_cid', '3': 6, '4': 1, '5': 9, '10': 'sdpCid'},
  ],
};

/// Descriptor for `SimulcastCodecInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulcastCodecInfoDescriptor =
    $convert.base64Decode('ChJTaW11bGNhc3RDb2RlY0luZm8SGwoJbWltZV90eXBlGAEgASgJUghtaW1lVHlwZRIQCgNtaW'
        'QYAiABKAlSA21pZBIQCgNjaWQYAyABKAlSA2NpZBIrCgZsYXllcnMYBCADKAsyEy5saXZla2l0'
        'LlZpZGVvTGF5ZXJSBmxheWVycxJCChB2aWRlb19sYXllcl9tb2RlGAUgASgOMhgubGl2ZWtpdC'
        '5WaWRlb0xheWVyLk1vZGVSDnZpZGVvTGF5ZXJNb2RlEhcKB3NkcF9jaWQYBiABKAlSBnNkcENp'
        'ZA==');

@$core.Deprecated('Use trackInfoDescriptor instead')
const TrackInfo$json = {
  '1': 'TrackInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.livekit.TrackType', '10': 'type'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'muted', '3': 4, '4': 1, '5': 8, '10': 'muted'},
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {
      '1': 'simulcast',
      '3': 7,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'simulcast',
    },
    {
      '1': 'disable_dtx',
      '3': 8,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'disableDtx',
    },
    {'1': 'source', '3': 9, '4': 1, '5': 14, '6': '.livekit.TrackSource', '10': 'source'},
    {
      '1': 'layers',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.livekit.VideoLayer',
      '8': {'3': true},
      '10': 'layers',
    },
    {'1': 'mime_type', '3': 11, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'mid', '3': 12, '4': 1, '5': 9, '10': 'mid'},
    {'1': 'codecs', '3': 13, '4': 3, '5': 11, '6': '.livekit.SimulcastCodecInfo', '10': 'codecs'},
    {
      '1': 'stereo',
      '3': 14,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'stereo',
    },
    {'1': 'disable_red', '3': 15, '4': 1, '5': 8, '10': 'disableRed'},
    {'1': 'encryption', '3': 16, '4': 1, '5': 14, '6': '.livekit.Encryption.Type', '10': 'encryption'},
    {'1': 'stream', '3': 17, '4': 1, '5': 9, '10': 'stream'},
    {'1': 'version', '3': 18, '4': 1, '5': 11, '6': '.livekit.TimedVersion', '10': 'version'},
    {'1': 'audio_features', '3': 19, '4': 3, '5': 14, '6': '.livekit.AudioTrackFeature', '10': 'audioFeatures'},
    {
      '1': 'backup_codec_policy',
      '3': 20,
      '4': 1,
      '5': 14,
      '6': '.livekit.BackupCodecPolicy',
      '10': 'backupCodecPolicy'
    },
  ],
};

/// Descriptor for `TrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackInfoDescriptor =
    $convert.base64Decode('CglUcmFja0luZm8SEAoDc2lkGAEgASgJUgNzaWQSJgoEdHlwZRgCIAEoDjISLmxpdmVraXQuVH'
        'JhY2tUeXBlUgR0eXBlEhgKBG5hbWUYAyABKAlCBIjsLAFSBG5hbWUSFAoFbXV0ZWQYBCABKAhS'
        'BW11dGVkEhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA1SBmhlaWdodBIgCg'
        'lzaW11bGNhc3QYByABKAhCAhgBUglzaW11bGNhc3QSIwoLZGlzYWJsZV9kdHgYCCABKAhCAhgB'
        'UgpkaXNhYmxlRHR4EiwKBnNvdXJjZRgJIAEoDjIULmxpdmVraXQuVHJhY2tTb3VyY2VSBnNvdX'
        'JjZRIvCgZsYXllcnMYCiADKAsyEy5saXZla2l0LlZpZGVvTGF5ZXJCAhgBUgZsYXllcnMSGwoJ'
        'bWltZV90eXBlGAsgASgJUghtaW1lVHlwZRIQCgNtaWQYDCABKAlSA21pZBIzCgZjb2RlY3MYDS'
        'ADKAsyGy5saXZla2l0LlNpbXVsY2FzdENvZGVjSW5mb1IGY29kZWNzEhoKBnN0ZXJlbxgOIAEo'
        'CEICGAFSBnN0ZXJlbxIfCgtkaXNhYmxlX3JlZBgPIAEoCFIKZGlzYWJsZVJlZBI4CgplbmNyeX'
        'B0aW9uGBAgASgOMhgubGl2ZWtpdC5FbmNyeXB0aW9uLlR5cGVSCmVuY3J5cHRpb24SFgoGc3Ry'
        'ZWFtGBEgASgJUgZzdHJlYW0SLwoHdmVyc2lvbhgSIAEoCzIVLmxpdmVraXQuVGltZWRWZXJzaW'
        '9uUgd2ZXJzaW9uEkEKDmF1ZGlvX2ZlYXR1cmVzGBMgAygOMhoubGl2ZWtpdC5BdWRpb1RyYWNr'
        'RmVhdHVyZVINYXVkaW9GZWF0dXJlcxJKChNiYWNrdXBfY29kZWNfcG9saWN5GBQgASgOMhoubG'
        'l2ZWtpdC5CYWNrdXBDb2RlY1BvbGljeVIRYmFja3VwQ29kZWNQb2xpY3k=');

@$core.Deprecated('Use dataTrackInfoDescriptor instead')
const DataTrackInfo$json = {
  '1': 'DataTrackInfo',
  '2': [
    {'1': 'pub_handle', '3': 1, '4': 1, '5': 13, '10': 'pubHandle'},
    {'1': 'sid', '3': 2, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'encryption', '3': 4, '4': 1, '5': 14, '6': '.livekit.Encryption.Type', '10': 'encryption'},
  ],
};

/// Descriptor for `DataTrackInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataTrackInfoDescriptor =
    $convert.base64Decode('Cg1EYXRhVHJhY2tJbmZvEh0KCnB1Yl9oYW5kbGUYASABKA1SCXB1YkhhbmRsZRIQCgNzaWQYAi'
        'ABKAlSA3NpZBISCgRuYW1lGAMgASgJUgRuYW1lEjgKCmVuY3J5cHRpb24YBCABKA4yGC5saXZl'
        'a2l0LkVuY3J5cHRpb24uVHlwZVIKZW5jcnlwdGlvbg==');

@$core.Deprecated('Use dataTrackExtensionParticipantSidDescriptor instead')
const DataTrackExtensionParticipantSid$json = {
  '1': 'DataTrackExtensionParticipantSid',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 14, '6': '.livekit.DataTrackExtensionID', '10': 'id'},
    {'1': 'participant_sid', '3': 2, '4': 1, '5': 9, '10': 'participantSid'},
  ],
};

/// Descriptor for `DataTrackExtensionParticipantSid`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataTrackExtensionParticipantSidDescriptor =
    $convert.base64Decode('CiBEYXRhVHJhY2tFeHRlbnNpb25QYXJ0aWNpcGFudFNpZBItCgJpZBgBIAEoDjIdLmxpdmVraX'
        'QuRGF0YVRyYWNrRXh0ZW5zaW9uSURSAmlkEicKD3BhcnRpY2lwYW50X3NpZBgCIAEoCVIOcGFy'
        'dGljaXBhbnRTaWQ=');

@$core.Deprecated('Use dataTrackSubscriptionOptionsDescriptor instead')
const DataTrackSubscriptionOptions$json = {
  '1': 'DataTrackSubscriptionOptions',
  '2': [
    {'1': 'target_fps', '3': 1, '4': 1, '5': 13, '9': 0, '10': 'targetFps', '17': true},
  ],
  '8': [
    {'1': '_target_fps'},
  ],
};

/// Descriptor for `DataTrackSubscriptionOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataTrackSubscriptionOptionsDescriptor =
    $convert.base64Decode('ChxEYXRhVHJhY2tTdWJzY3JpcHRpb25PcHRpb25zEiIKCnRhcmdldF9mcHMYASABKA1IAFIJdG'
        'FyZ2V0RnBziAEBQg0KC190YXJnZXRfZnBz');

@$core.Deprecated('Use videoLayerDescriptor instead')
const VideoLayer$json = {
  '1': 'VideoLayer',
  '2': [
    {'1': 'quality', '3': 1, '4': 1, '5': 14, '6': '.livekit.VideoQuality', '10': 'quality'},
    {'1': 'width', '3': 2, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 13, '10': 'height'},
    {'1': 'bitrate', '3': 4, '4': 1, '5': 13, '10': 'bitrate'},
    {'1': 'ssrc', '3': 5, '4': 1, '5': 13, '10': 'ssrc'},
    {'1': 'spatial_layer', '3': 6, '4': 1, '5': 5, '10': 'spatialLayer'},
    {'1': 'rid', '3': 7, '4': 1, '5': 9, '10': 'rid'},
    {'1': 'repair_ssrc', '3': 8, '4': 1, '5': 13, '10': 'repairSsrc'},
  ],
  '4': [VideoLayer_Mode$json],
};

@$core.Deprecated('Use videoLayerDescriptor instead')
const VideoLayer_Mode$json = {
  '1': 'Mode',
  '2': [
    {'1': 'MODE_UNUSED', '2': 0},
    {'1': 'ONE_SPATIAL_LAYER_PER_STREAM', '2': 1},
    {'1': 'MULTIPLE_SPATIAL_LAYERS_PER_STREAM', '2': 2},
    {'1': 'ONE_SPATIAL_LAYER_PER_STREAM_INCOMPLETE_RTCP_SR', '2': 3},
  ],
};

/// Descriptor for `VideoLayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoLayerDescriptor =
    $convert.base64Decode('CgpWaWRlb0xheWVyEi8KB3F1YWxpdHkYASABKA4yFS5saXZla2l0LlZpZGVvUXVhbGl0eVIHcX'
        'VhbGl0eRIUCgV3aWR0aBgCIAEoDVIFd2lkdGgSFgoGaGVpZ2h0GAMgASgNUgZoZWlnaHQSGAoH'
        'Yml0cmF0ZRgEIAEoDVIHYml0cmF0ZRISCgRzc3JjGAUgASgNUgRzc3JjEiMKDXNwYXRpYWxfbG'
        'F5ZXIYBiABKAVSDHNwYXRpYWxMYXllchIQCgNyaWQYByABKAlSA3JpZBIfCgtyZXBhaXJfc3Ny'
        'YxgIIAEoDVIKcmVwYWlyU3NyYyKWAQoETW9kZRIPCgtNT0RFX1VOVVNFRBAAEiAKHE9ORV9TUE'
        'FUSUFMX0xBWUVSX1BFUl9TVFJFQU0QARImCiJNVUxUSVBMRV9TUEFUSUFMX0xBWUVSU19QRVJf'
        'U1RSRUFNEAISMwovT05FX1NQQVRJQUxfTEFZRVJfUEVSX1NUUkVBTV9JTkNPTVBMRVRFX1JUQ1'
        'BfU1IQAw==');

@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket$json = {
  '1': 'DataPacket',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.livekit.DataPacket.Kind',
      '8': {'3': true},
      '10': 'kind',
    },
    {'1': 'participant_identity', '3': 4, '4': 1, '5': 9, '10': 'participantIdentity'},
    {'1': 'destination_identities', '3': 5, '4': 3, '5': 9, '10': 'destinationIdentities'},
    {'1': 'user', '3': 2, '4': 1, '5': 11, '6': '.livekit.UserPacket', '9': 0, '10': 'user'},
    {
      '1': 'speaker',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekit.ActiveSpeakerUpdate',
      '8': {'3': true},
      '9': 0,
      '10': 'speaker',
    },
    {'1': 'sip_dtmf', '3': 6, '4': 1, '5': 11, '6': '.livekit.SipDTMF', '9': 0, '10': 'sipDtmf'},
    {'1': 'transcription', '3': 7, '4': 1, '5': 11, '6': '.livekit.Transcription', '9': 0, '10': 'transcription'},
    {'1': 'metrics', '3': 8, '4': 1, '5': 11, '6': '.livekit.MetricsBatch', '9': 0, '10': 'metrics'},
    {'1': 'chat_message', '3': 9, '4': 1, '5': 11, '6': '.livekit.ChatMessage', '9': 0, '10': 'chatMessage'},
    {'1': 'rpc_request', '3': 10, '4': 1, '5': 11, '6': '.livekit.RpcRequest', '9': 0, '10': 'rpcRequest'},
    {'1': 'rpc_ack', '3': 11, '4': 1, '5': 11, '6': '.livekit.RpcAck', '9': 0, '10': 'rpcAck'},
    {'1': 'rpc_response', '3': 12, '4': 1, '5': 11, '6': '.livekit.RpcResponse', '9': 0, '10': 'rpcResponse'},
    {'1': 'stream_header', '3': 13, '4': 1, '5': 11, '6': '.livekit.DataStream.Header', '9': 0, '10': 'streamHeader'},
    {'1': 'stream_chunk', '3': 14, '4': 1, '5': 11, '6': '.livekit.DataStream.Chunk', '9': 0, '10': 'streamChunk'},
    {
      '1': 'stream_trailer',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.DataStream.Trailer',
      '9': 0,
      '10': 'streamTrailer'
    },
    {
      '1': 'encrypted_packet',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.livekit.EncryptedPacket',
      '9': 0,
      '10': 'encryptedPacket'
    },
    {'1': 'sequence', '3': 16, '4': 1, '5': 13, '10': 'sequence'},
    {'1': 'participant_sid', '3': 17, '4': 1, '5': 9, '10': 'participantSid'},
  ],
  '4': [DataPacket_Kind$json],
  '8': [
    {'1': 'value'},
  ],
};

@$core.Deprecated('Use dataPacketDescriptor instead')
const DataPacket_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'RELIABLE', '2': 0},
    {'1': 'LOSSY', '2': 1},
  ],
};

/// Descriptor for `DataPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataPacketDescriptor =
    $convert.base64Decode('CgpEYXRhUGFja2V0EjAKBGtpbmQYASABKA4yGC5saXZla2l0LkRhdGFQYWNrZXQuS2luZEICGA'
        'FSBGtpbmQSMQoUcGFydGljaXBhbnRfaWRlbnRpdHkYBCABKAlSE3BhcnRpY2lwYW50SWRlbnRp'
        'dHkSNQoWZGVzdGluYXRpb25faWRlbnRpdGllcxgFIAMoCVIVZGVzdGluYXRpb25JZGVudGl0aW'
        'VzEikKBHVzZXIYAiABKAsyEy5saXZla2l0LlVzZXJQYWNrZXRIAFIEdXNlchI8CgdzcGVha2Vy'
        'GAMgASgLMhwubGl2ZWtpdC5BY3RpdmVTcGVha2VyVXBkYXRlQgIYAUgAUgdzcGVha2VyEi0KCH'
        'NpcF9kdG1mGAYgASgLMhAubGl2ZWtpdC5TaXBEVE1GSABSB3NpcER0bWYSPgoNdHJhbnNjcmlw'
        'dGlvbhgHIAEoCzIWLmxpdmVraXQuVHJhbnNjcmlwdGlvbkgAUg10cmFuc2NyaXB0aW9uEjEKB2'
        '1ldHJpY3MYCCABKAsyFS5saXZla2l0Lk1ldHJpY3NCYXRjaEgAUgdtZXRyaWNzEjkKDGNoYXRf'
        'bWVzc2FnZRgJIAEoCzIULmxpdmVraXQuQ2hhdE1lc3NhZ2VIAFILY2hhdE1lc3NhZ2USNgoLcn'
        'BjX3JlcXVlc3QYCiABKAsyEy5saXZla2l0LlJwY1JlcXVlc3RIAFIKcnBjUmVxdWVzdBIqCgdy'
        'cGNfYWNrGAsgASgLMg8ubGl2ZWtpdC5ScGNBY2tIAFIGcnBjQWNrEjkKDHJwY19yZXNwb25zZR'
        'gMIAEoCzIULmxpdmVraXQuUnBjUmVzcG9uc2VIAFILcnBjUmVzcG9uc2USQQoNc3RyZWFtX2hl'
        'YWRlchgNIAEoCzIaLmxpdmVraXQuRGF0YVN0cmVhbS5IZWFkZXJIAFIMc3RyZWFtSGVhZGVyEj'
        '4KDHN0cmVhbV9jaHVuaxgOIAEoCzIZLmxpdmVraXQuRGF0YVN0cmVhbS5DaHVua0gAUgtzdHJl'
        'YW1DaHVuaxJECg5zdHJlYW1fdHJhaWxlchgPIAEoCzIbLmxpdmVraXQuRGF0YVN0cmVhbS5Ucm'
        'FpbGVySABSDXN0cmVhbVRyYWlsZXISRQoQZW5jcnlwdGVkX3BhY2tldBgSIAEoCzIYLmxpdmVr'
        'aXQuRW5jcnlwdGVkUGFja2V0SABSD2VuY3J5cHRlZFBhY2tldBIaCghzZXF1ZW5jZRgQIAEoDV'
        'IIc2VxdWVuY2USJwoPcGFydGljaXBhbnRfc2lkGBEgASgJUg5wYXJ0aWNpcGFudFNpZCIfCgRL'
        'aW5kEgwKCFJFTElBQkxFEAASCQoFTE9TU1kQAUIHCgV2YWx1ZQ==');

@$core.Deprecated('Use encryptedPacketDescriptor instead')
const EncryptedPacket$json = {
  '1': 'EncryptedPacket',
  '2': [
    {'1': 'encryption_type', '3': 1, '4': 1, '5': 14, '6': '.livekit.Encryption.Type', '10': 'encryptionType'},
    {'1': 'iv', '3': 2, '4': 1, '5': 12, '10': 'iv'},
    {'1': 'key_index', '3': 3, '4': 1, '5': 13, '10': 'keyIndex'},
    {'1': 'encrypted_value', '3': 4, '4': 1, '5': 12, '10': 'encryptedValue'},
  ],
};

/// Descriptor for `EncryptedPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedPacketDescriptor =
    $convert.base64Decode('Cg9FbmNyeXB0ZWRQYWNrZXQSQQoPZW5jcnlwdGlvbl90eXBlGAEgASgOMhgubGl2ZWtpdC5Fbm'
        'NyeXB0aW9uLlR5cGVSDmVuY3J5cHRpb25UeXBlEg4KAml2GAIgASgMUgJpdhIbCglrZXlfaW5k'
        'ZXgYAyABKA1SCGtleUluZGV4EicKD2VuY3J5cHRlZF92YWx1ZRgEIAEoDFIOZW5jcnlwdGVkVm'
        'FsdWU=');

@$core.Deprecated('Use encryptedPacketPayloadDescriptor instead')
const EncryptedPacketPayload$json = {
  '1': 'EncryptedPacketPayload',
  '2': [
    {'1': 'user', '3': 1, '4': 1, '5': 11, '6': '.livekit.UserPacket', '9': 0, '10': 'user'},
    {'1': 'chat_message', '3': 3, '4': 1, '5': 11, '6': '.livekit.ChatMessage', '9': 0, '10': 'chatMessage'},
    {'1': 'rpc_request', '3': 4, '4': 1, '5': 11, '6': '.livekit.RpcRequest', '9': 0, '10': 'rpcRequest'},
    {'1': 'rpc_ack', '3': 5, '4': 1, '5': 11, '6': '.livekit.RpcAck', '9': 0, '10': 'rpcAck'},
    {'1': 'rpc_response', '3': 6, '4': 1, '5': 11, '6': '.livekit.RpcResponse', '9': 0, '10': 'rpcResponse'},
    {'1': 'stream_header', '3': 7, '4': 1, '5': 11, '6': '.livekit.DataStream.Header', '9': 0, '10': 'streamHeader'},
    {'1': 'stream_chunk', '3': 8, '4': 1, '5': 11, '6': '.livekit.DataStream.Chunk', '9': 0, '10': 'streamChunk'},
    {'1': 'stream_trailer', '3': 9, '4': 1, '5': 11, '6': '.livekit.DataStream.Trailer', '9': 0, '10': 'streamTrailer'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `EncryptedPacketPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedPacketPayloadDescriptor =
    $convert.base64Decode('ChZFbmNyeXB0ZWRQYWNrZXRQYXlsb2FkEikKBHVzZXIYASABKAsyEy5saXZla2l0LlVzZXJQYW'
        'NrZXRIAFIEdXNlchI5CgxjaGF0X21lc3NhZ2UYAyABKAsyFC5saXZla2l0LkNoYXRNZXNzYWdl'
        'SABSC2NoYXRNZXNzYWdlEjYKC3JwY19yZXF1ZXN0GAQgASgLMhMubGl2ZWtpdC5ScGNSZXF1ZX'
        'N0SABSCnJwY1JlcXVlc3QSKgoHcnBjX2FjaxgFIAEoCzIPLmxpdmVraXQuUnBjQWNrSABSBnJw'
        'Y0FjaxI5CgxycGNfcmVzcG9uc2UYBiABKAsyFC5saXZla2l0LlJwY1Jlc3BvbnNlSABSC3JwY1'
        'Jlc3BvbnNlEkEKDXN0cmVhbV9oZWFkZXIYByABKAsyGi5saXZla2l0LkRhdGFTdHJlYW0uSGVh'
        'ZGVySABSDHN0cmVhbUhlYWRlchI+CgxzdHJlYW1fY2h1bmsYCCABKAsyGS5saXZla2l0LkRhdG'
        'FTdHJlYW0uQ2h1bmtIAFILc3RyZWFtQ2h1bmsSRAoOc3RyZWFtX3RyYWlsZXIYCSABKAsyGy5s'
        'aXZla2l0LkRhdGFTdHJlYW0uVHJhaWxlckgAUg1zdHJlYW1UcmFpbGVyQgcKBXZhbHVl');

@$core.Deprecated('Use activeSpeakerUpdateDescriptor instead')
const ActiveSpeakerUpdate$json = {
  '1': 'ActiveSpeakerUpdate',
  '2': [
    {'1': 'speakers', '3': 1, '4': 3, '5': 11, '6': '.livekit.SpeakerInfo', '10': 'speakers'},
  ],
  '7': {'3': true},
};

/// Descriptor for `ActiveSpeakerUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeSpeakerUpdateDescriptor =
    $convert.base64Decode('ChNBY3RpdmVTcGVha2VyVXBkYXRlEjAKCHNwZWFrZXJzGAEgAygLMhQubGl2ZWtpdC5TcGVha2'
        'VySW5mb1IIc3BlYWtlcnM6AhgB');

@$core.Deprecated('Use speakerInfoDescriptor instead')
const SpeakerInfo$json = {
  '1': 'SpeakerInfo',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'level', '3': 2, '4': 1, '5': 2, '10': 'level'},
    {'1': 'active', '3': 3, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `SpeakerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakerInfoDescriptor =
    $convert.base64Decode('CgtTcGVha2VySW5mbxIQCgNzaWQYASABKAlSA3NpZBIUCgVsZXZlbBgCIAEoAlIFbGV2ZWwSFg'
        'oGYWN0aXZlGAMgASgIUgZhY3RpdmU=');

@$core.Deprecated('Use userPacketDescriptor instead')
const UserPacket$json = {
  '1': 'UserPacket',
  '2': [
    {
      '1': 'participant_sid',
      '3': 1,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'participantSid',
    },
    {
      '1': 'participant_identity',
      '3': 5,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'participantIdentity',
    },
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
    {
      '1': 'destination_sids',
      '3': 3,
      '4': 3,
      '5': 9,
      '8': {'3': true},
      '10': 'destinationSids',
    },
    {
      '1': 'destination_identities',
      '3': 6,
      '4': 3,
      '5': 9,
      '8': {'3': true},
      '10': 'destinationIdentities',
    },
    {'1': 'topic', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'topic', '17': true},
    {'1': 'id', '3': 8, '4': 1, '5': 9, '9': 1, '10': 'id', '17': true},
    {'1': 'start_time', '3': 9, '4': 1, '5': 4, '9': 2, '10': 'startTime', '17': true},
    {'1': 'end_time', '3': 10, '4': 1, '5': 4, '9': 3, '10': 'endTime', '17': true},
    {'1': 'nonce', '3': 11, '4': 1, '5': 12, '10': 'nonce'},
  ],
  '8': [
    {'1': '_topic'},
    {'1': '_id'},
    {'1': '_start_time'},
    {'1': '_end_time'},
  ],
};

/// Descriptor for `UserPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPacketDescriptor =
    $convert.base64Decode('CgpVc2VyUGFja2V0EisKD3BhcnRpY2lwYW50X3NpZBgBIAEoCUICGAFSDnBhcnRpY2lwYW50U2'
        'lkEjUKFHBhcnRpY2lwYW50X2lkZW50aXR5GAUgASgJQgIYAVITcGFydGljaXBhbnRJZGVudGl0'
        'eRIYCgdwYXlsb2FkGAIgASgMUgdwYXlsb2FkEi0KEGRlc3RpbmF0aW9uX3NpZHMYAyADKAlCAh'
        'gBUg9kZXN0aW5hdGlvblNpZHMSOQoWZGVzdGluYXRpb25faWRlbnRpdGllcxgGIAMoCUICGAFS'
        'FWRlc3RpbmF0aW9uSWRlbnRpdGllcxIZCgV0b3BpYxgEIAEoCUgAUgV0b3BpY4gBARITCgJpZB'
        'gIIAEoCUgBUgJpZIgBARIiCgpzdGFydF90aW1lGAkgASgESAJSCXN0YXJ0VGltZYgBARIeCghl'
        'bmRfdGltZRgKIAEoBEgDUgdlbmRUaW1liAEBEhQKBW5vbmNlGAsgASgMUgVub25jZUIICgZfdG'
        '9waWNCBQoDX2lkQg0KC19zdGFydF90aW1lQgsKCV9lbmRfdGltZQ==');

@$core.Deprecated('Use sipDTMFDescriptor instead')
const SipDTMF$json = {
  '1': 'SipDTMF',
  '2': [
    {'1': 'code', '3': 3, '4': 1, '5': 13, '10': 'code'},
    {'1': 'digit', '3': 4, '4': 1, '5': 9, '10': 'digit'},
  ],
};

/// Descriptor for `SipDTMF`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sipDTMFDescriptor =
    $convert.base64Decode('CgdTaXBEVE1GEhIKBGNvZGUYAyABKA1SBGNvZGUSFAoFZGlnaXQYBCABKAlSBWRpZ2l0');

@$core.Deprecated('Use transcriptionDescriptor instead')
const Transcription$json = {
  '1': 'Transcription',
  '2': [
    {'1': 'transcribed_participant_identity', '3': 2, '4': 1, '5': 9, '10': 'transcribedParticipantIdentity'},
    {'1': 'track_id', '3': 3, '4': 1, '5': 9, '10': 'trackId'},
    {'1': 'segments', '3': 4, '4': 3, '5': 11, '6': '.livekit.TranscriptionSegment', '10': 'segments'},
  ],
};

/// Descriptor for `Transcription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcriptionDescriptor =
    $convert.base64Decode('Cg1UcmFuc2NyaXB0aW9uEkgKIHRyYW5zY3JpYmVkX3BhcnRpY2lwYW50X2lkZW50aXR5GAIgAS'
        'gJUh50cmFuc2NyaWJlZFBhcnRpY2lwYW50SWRlbnRpdHkSGQoIdHJhY2tfaWQYAyABKAlSB3Ry'
        'YWNrSWQSOQoIc2VnbWVudHMYBCADKAsyHS5saXZla2l0LlRyYW5zY3JpcHRpb25TZWdtZW50Ug'
        'hzZWdtZW50cw==');

@$core.Deprecated('Use transcriptionSegmentDescriptor instead')
const TranscriptionSegment$json = {
  '1': 'TranscriptionSegment',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'start_time', '3': 3, '4': 1, '5': 4, '10': 'startTime'},
    {'1': 'end_time', '3': 4, '4': 1, '5': 4, '10': 'endTime'},
    {'1': 'final', '3': 5, '4': 1, '5': 8, '10': 'final'},
    {'1': 'language', '3': 6, '4': 1, '5': 9, '10': 'language'},
  ],
};

/// Descriptor for `TranscriptionSegment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcriptionSegmentDescriptor =
    $convert.base64Decode('ChRUcmFuc2NyaXB0aW9uU2VnbWVudBIOCgJpZBgBIAEoCVICaWQSEgoEdGV4dBgCIAEoCVIEdG'
        'V4dBIdCgpzdGFydF90aW1lGAMgASgEUglzdGFydFRpbWUSGQoIZW5kX3RpbWUYBCABKARSB2Vu'
        'ZFRpbWUSFAoFZmluYWwYBSABKAhSBWZpbmFsEhoKCGxhbmd1YWdlGAYgASgJUghsYW5ndWFnZQ'
        '==');

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'edit_timestamp', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'editTimestamp', '17': true},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {'1': 'deleted', '3': 5, '4': 1, '5': 8, '10': 'deleted'},
    {'1': 'generated', '3': 6, '4': 1, '5': 8, '10': 'generated'},
  ],
  '8': [
    {'1': '_edit_timestamp'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor =
    $convert.base64Decode('CgtDaGF0TWVzc2FnZRIOCgJpZBgBIAEoCVICaWQSHAoJdGltZXN0YW1wGAIgASgDUgl0aW1lc3'
        'RhbXASKgoOZWRpdF90aW1lc3RhbXAYAyABKANIAFINZWRpdFRpbWVzdGFtcIgBARIYCgdtZXNz'
        'YWdlGAQgASgJUgdtZXNzYWdlEhgKB2RlbGV0ZWQYBSABKAhSB2RlbGV0ZWQSHAoJZ2VuZXJhdG'
        'VkGAYgASgIUglnZW5lcmF0ZWRCEQoPX2VkaXRfdGltZXN0YW1w');

@$core.Deprecated('Use rpcRequestDescriptor instead')
const RpcRequest$json = {
  '1': 'RpcRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'method', '3': 2, '4': 1, '5': 9, '10': 'method'},
    {'1': 'payload', '3': 3, '4': 1, '5': 9, '10': 'payload'},
    {'1': 'response_timeout_ms', '3': 4, '4': 1, '5': 13, '10': 'responseTimeoutMs'},
    {'1': 'version', '3': 5, '4': 1, '5': 13, '10': 'version'},
  ],
};

/// Descriptor for `RpcRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rpcRequestDescriptor =
    $convert.base64Decode('CgpScGNSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIWCgZtZXRob2QYAiABKAlSBm1ldGhvZBIYCg'
        'dwYXlsb2FkGAMgASgJUgdwYXlsb2FkEi4KE3Jlc3BvbnNlX3RpbWVvdXRfbXMYBCABKA1SEXJl'
        'c3BvbnNlVGltZW91dE1zEhgKB3ZlcnNpb24YBSABKA1SB3ZlcnNpb24=');

@$core.Deprecated('Use rpcAckDescriptor instead')
const RpcAck$json = {
  '1': 'RpcAck',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
  ],
};

/// Descriptor for `RpcAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rpcAckDescriptor =
    $convert.base64Decode('CgZScGNBY2sSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdElk');

@$core.Deprecated('Use rpcResponseDescriptor instead')
const RpcResponse$json = {
  '1': 'RpcResponse',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'payload', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'payload'},
    {'1': 'error', '3': 3, '4': 1, '5': 11, '6': '.livekit.RpcError', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `RpcResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rpcResponseDescriptor =
    $convert.base64Decode('CgtScGNSZXNwb25zZRIdCgpyZXF1ZXN0X2lkGAEgASgJUglyZXF1ZXN0SWQSGgoHcGF5bG9hZB'
        'gCIAEoCUgAUgdwYXlsb2FkEikKBWVycm9yGAMgASgLMhEubGl2ZWtpdC5ScGNFcnJvckgAUgVl'
        'cnJvckIHCgV2YWx1ZQ==');

@$core.Deprecated('Use rpcErrorDescriptor instead')
const RpcError$json = {
  '1': 'RpcError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 13, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'data', '3': 3, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `RpcError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rpcErrorDescriptor =
    $convert.base64Decode('CghScGNFcnJvchISCgRjb2RlGAEgASgNUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2'
        'USEgoEZGF0YRgDIAEoCVIEZGF0YQ==');

@$core.Deprecated('Use participantTracksDescriptor instead')
const ParticipantTracks$json = {
  '1': 'ParticipantTracks',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sids', '3': 2, '4': 3, '5': 9, '10': 'trackSids'},
  ],
};

/// Descriptor for `ParticipantTracks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantTracksDescriptor =
    $convert.base64Decode('ChFQYXJ0aWNpcGFudFRyYWNrcxInCg9wYXJ0aWNpcGFudF9zaWQYASABKAlSDnBhcnRpY2lwYW'
        '50U2lkEh0KCnRyYWNrX3NpZHMYAiADKAlSCXRyYWNrU2lkcw==');

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = {
  '1': 'ServerInfo',
  '2': [
    {'1': 'edition', '3': 1, '4': 1, '5': 14, '6': '.livekit.ServerInfo.Edition', '10': 'edition'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    {'1': 'region', '3': 4, '4': 1, '5': 9, '10': 'region'},
    {'1': 'node_id', '3': 5, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'debug_info', '3': 6, '4': 1, '5': 9, '10': 'debugInfo'},
    {'1': 'agent_protocol', '3': 7, '4': 1, '5': 5, '10': 'agentProtocol'},
  ],
  '4': [ServerInfo_Edition$json],
};

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo_Edition$json = {
  '1': 'Edition',
  '2': [
    {'1': 'Standard', '2': 0},
    {'1': 'Cloud', '2': 1},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor =
    $convert.base64Decode('CgpTZXJ2ZXJJbmZvEjUKB2VkaXRpb24YASABKA4yGy5saXZla2l0LlNlcnZlckluZm8uRWRpdG'
        'lvblIHZWRpdGlvbhIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgF'
        'Ughwcm90b2NvbBIWCgZyZWdpb24YBCABKAlSBnJlZ2lvbhIXCgdub2RlX2lkGAUgASgJUgZub2'
        'RlSWQSHQoKZGVidWdfaW5mbxgGIAEoCVIJZGVidWdJbmZvEiUKDmFnZW50X3Byb3RvY29sGAcg'
        'ASgFUg1hZ2VudFByb3RvY29sIiIKB0VkaXRpb24SDAoIU3RhbmRhcmQQABIJCgVDbG91ZBAB');

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo$json = {
  '1': 'ClientInfo',
  '2': [
    {'1': 'sdk', '3': 1, '4': 1, '5': 14, '6': '.livekit.ClientInfo.SDK', '10': 'sdk'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 5, '10': 'protocol'},
    {'1': 'os', '3': 4, '4': 1, '5': 9, '10': 'os'},
    {'1': 'os_version', '3': 5, '4': 1, '5': 9, '10': 'osVersion'},
    {'1': 'device_model', '3': 6, '4': 1, '5': 9, '10': 'deviceModel'},
    {'1': 'browser', '3': 7, '4': 1, '5': 9, '10': 'browser'},
    {'1': 'browser_version', '3': 8, '4': 1, '5': 9, '10': 'browserVersion'},
    {'1': 'address', '3': 9, '4': 1, '5': 9, '10': 'address'},
    {'1': 'network', '3': 10, '4': 1, '5': 9, '10': 'network'},
    {'1': 'other_sdks', '3': 11, '4': 1, '5': 9, '10': 'otherSdks'},
  ],
  '4': [ClientInfo_SDK$json],
};

@$core.Deprecated('Use clientInfoDescriptor instead')
const ClientInfo_SDK$json = {
  '1': 'SDK',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'JS', '2': 1},
    {'1': 'SWIFT', '2': 2},
    {'1': 'ANDROID', '2': 3},
    {'1': 'FLUTTER', '2': 4},
    {'1': 'GO', '2': 5},
    {'1': 'UNITY', '2': 6},
    {'1': 'REACT_NATIVE', '2': 7},
    {'1': 'RUST', '2': 8},
    {'1': 'PYTHON', '2': 9},
    {'1': 'CPP', '2': 10},
    {'1': 'UNITY_WEB', '2': 11},
    {'1': 'NODE', '2': 12},
    {'1': 'UNREAL', '2': 13},
    {'1': 'ESP32', '2': 14},
  ],
};

/// Descriptor for `ClientInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientInfoDescriptor =
    $convert.base64Decode('CgpDbGllbnRJbmZvEikKA3NkaxgBIAEoDjIXLmxpdmVraXQuQ2xpZW50SW5mby5TREtSA3Nkax'
        'IYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhoKCHByb3RvY29sGAMgASgFUghwcm90b2NvbBIO'
        'CgJvcxgEIAEoCVICb3MSHQoKb3NfdmVyc2lvbhgFIAEoCVIJb3NWZXJzaW9uEiEKDGRldmljZV'
        '9tb2RlbBgGIAEoCVILZGV2aWNlTW9kZWwSGAoHYnJvd3NlchgHIAEoCVIHYnJvd3NlchInCg9i'
        'cm93c2VyX3ZlcnNpb24YCCABKAlSDmJyb3dzZXJWZXJzaW9uEhgKB2FkZHJlc3MYCSABKAlSB2'
        'FkZHJlc3MSGAoHbmV0d29yaxgKIAEoCVIHbmV0d29yaxIdCgpvdGhlcl9zZGtzGAsgASgJUglv'
        'dGhlclNka3MiswEKA1NESxILCgdVTktOT1dOEAASBgoCSlMQARIJCgVTV0lGVBACEgsKB0FORF'
        'JPSUQQAxILCgdGTFVUVEVSEAQSBgoCR08QBRIJCgVVTklUWRAGEhAKDFJFQUNUX05BVElWRRAH'
        'EggKBFJVU1QQCBIKCgZQWVRIT04QCRIHCgNDUFAQChINCglVTklUWV9XRUIQCxIICgROT0RFEA'
        'wSCgoGVU5SRUFMEA0SCQoFRVNQMzIQDg==');

@$core.Deprecated('Use clientConfigurationDescriptor instead')
const ClientConfiguration$json = {
  '1': 'ClientConfiguration',
  '2': [
    {'1': 'video', '3': 1, '4': 1, '5': 11, '6': '.livekit.VideoConfiguration', '10': 'video'},
    {'1': 'screen', '3': 2, '4': 1, '5': 11, '6': '.livekit.VideoConfiguration', '10': 'screen'},
    {'1': 'resume_connection', '3': 3, '4': 1, '5': 14, '6': '.livekit.ClientConfigSetting', '10': 'resumeConnection'},
    {'1': 'disabled_codecs', '3': 4, '4': 1, '5': 11, '6': '.livekit.DisabledCodecs', '10': 'disabledCodecs'},
    {'1': 'force_relay', '3': 5, '4': 1, '5': 14, '6': '.livekit.ClientConfigSetting', '10': 'forceRelay'},
  ],
};

/// Descriptor for `ClientConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientConfigurationDescriptor =
    $convert.base64Decode('ChNDbGllbnRDb25maWd1cmF0aW9uEjEKBXZpZGVvGAEgASgLMhsubGl2ZWtpdC5WaWRlb0Nvbm'
        'ZpZ3VyYXRpb25SBXZpZGVvEjMKBnNjcmVlbhgCIAEoCzIbLmxpdmVraXQuVmlkZW9Db25maWd1'
        'cmF0aW9uUgZzY3JlZW4SSQoRcmVzdW1lX2Nvbm5lY3Rpb24YAyABKA4yHC5saXZla2l0LkNsaW'
        'VudENvbmZpZ1NldHRpbmdSEHJlc3VtZUNvbm5lY3Rpb24SQAoPZGlzYWJsZWRfY29kZWNzGAQg'
        'ASgLMhcubGl2ZWtpdC5EaXNhYmxlZENvZGVjc1IOZGlzYWJsZWRDb2RlY3MSPQoLZm9yY2Vfcm'
        'VsYXkYBSABKA4yHC5saXZla2l0LkNsaWVudENvbmZpZ1NldHRpbmdSCmZvcmNlUmVsYXk=');

@$core.Deprecated('Use videoConfigurationDescriptor instead')
const VideoConfiguration$json = {
  '1': 'VideoConfiguration',
  '2': [
    {'1': 'hardware_encoder', '3': 1, '4': 1, '5': 14, '6': '.livekit.ClientConfigSetting', '10': 'hardwareEncoder'},
  ],
};

/// Descriptor for `VideoConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoConfigurationDescriptor =
    $convert.base64Decode('ChJWaWRlb0NvbmZpZ3VyYXRpb24SRwoQaGFyZHdhcmVfZW5jb2RlchgBIAEoDjIcLmxpdmVraX'
        'QuQ2xpZW50Q29uZmlnU2V0dGluZ1IPaGFyZHdhcmVFbmNvZGVy');

@$core.Deprecated('Use disabledCodecsDescriptor instead')
const DisabledCodecs$json = {
  '1': 'DisabledCodecs',
  '2': [
    {'1': 'codecs', '3': 1, '4': 3, '5': 11, '6': '.livekit.Codec', '10': 'codecs'},
    {'1': 'publish', '3': 2, '4': 3, '5': 11, '6': '.livekit.Codec', '10': 'publish'},
  ],
};

/// Descriptor for `DisabledCodecs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disabledCodecsDescriptor =
    $convert.base64Decode('Cg5EaXNhYmxlZENvZGVjcxImCgZjb2RlY3MYASADKAsyDi5saXZla2l0LkNvZGVjUgZjb2RlY3'
        'MSKAoHcHVibGlzaBgCIAMoCzIOLmxpdmVraXQuQ29kZWNSB3B1Ymxpc2g=');

@$core.Deprecated('Use rTPDriftDescriptor instead')
const RTPDrift$json = {
  '1': 'RTPDrift',
  '2': [
    {'1': 'start_time', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    {'1': 'end_time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endTime'},
    {'1': 'duration', '3': 3, '4': 1, '5': 1, '10': 'duration'},
    {'1': 'start_timestamp', '3': 4, '4': 1, '5': 4, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 5, '4': 1, '5': 4, '10': 'endTimestamp'},
    {'1': 'rtp_clock_ticks', '3': 6, '4': 1, '5': 4, '10': 'rtpClockTicks'},
    {'1': 'drift_samples', '3': 7, '4': 1, '5': 3, '10': 'driftSamples'},
    {'1': 'drift_ms', '3': 8, '4': 1, '5': 1, '10': 'driftMs'},
    {'1': 'clock_rate', '3': 9, '4': 1, '5': 1, '10': 'clockRate'},
  ],
};

/// Descriptor for `RTPDrift`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPDriftDescriptor =
    $convert.base64Decode('CghSVFBEcmlmdBI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
        'FtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
        'dGFtcFIHZW5kVGltZRIaCghkdXJhdGlvbhgDIAEoAVIIZHVyYXRpb24SJwoPc3RhcnRfdGltZX'
        'N0YW1wGAQgASgEUg5zdGFydFRpbWVzdGFtcBIjCg1lbmRfdGltZXN0YW1wGAUgASgEUgxlbmRU'
        'aW1lc3RhbXASJgoPcnRwX2Nsb2NrX3RpY2tzGAYgASgEUg1ydHBDbG9ja1RpY2tzEiMKDWRyaW'
        'Z0X3NhbXBsZXMYByABKANSDGRyaWZ0U2FtcGxlcxIZCghkcmlmdF9tcxgIIAEoAVIHZHJpZnRN'
        'cxIdCgpjbG9ja19yYXRlGAkgASgBUgljbG9ja1JhdGU=');

@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats$json = {
  '1': 'RTPStats',
  '2': [
    {'1': 'start_time', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    {'1': 'end_time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endTime'},
    {'1': 'duration', '3': 3, '4': 1, '5': 1, '10': 'duration'},
    {'1': 'packets', '3': 4, '4': 1, '5': 13, '10': 'packets'},
    {'1': 'packet_rate', '3': 5, '4': 1, '5': 1, '10': 'packetRate'},
    {'1': 'bytes', '3': 6, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'header_bytes', '3': 39, '4': 1, '5': 4, '10': 'headerBytes'},
    {'1': 'bitrate', '3': 7, '4': 1, '5': 1, '10': 'bitrate'},
    {'1': 'packets_lost', '3': 8, '4': 1, '5': 13, '10': 'packetsLost'},
    {'1': 'packet_loss_rate', '3': 9, '4': 1, '5': 1, '10': 'packetLossRate'},
    {'1': 'packet_loss_percentage', '3': 10, '4': 1, '5': 2, '10': 'packetLossPercentage'},
    {'1': 'packets_duplicate', '3': 11, '4': 1, '5': 13, '10': 'packetsDuplicate'},
    {'1': 'packet_duplicate_rate', '3': 12, '4': 1, '5': 1, '10': 'packetDuplicateRate'},
    {'1': 'bytes_duplicate', '3': 13, '4': 1, '5': 4, '10': 'bytesDuplicate'},
    {'1': 'header_bytes_duplicate', '3': 40, '4': 1, '5': 4, '10': 'headerBytesDuplicate'},
    {'1': 'bitrate_duplicate', '3': 14, '4': 1, '5': 1, '10': 'bitrateDuplicate'},
    {'1': 'packets_padding', '3': 15, '4': 1, '5': 13, '10': 'packetsPadding'},
    {'1': 'packet_padding_rate', '3': 16, '4': 1, '5': 1, '10': 'packetPaddingRate'},
    {'1': 'bytes_padding', '3': 17, '4': 1, '5': 4, '10': 'bytesPadding'},
    {'1': 'header_bytes_padding', '3': 41, '4': 1, '5': 4, '10': 'headerBytesPadding'},
    {'1': 'bitrate_padding', '3': 18, '4': 1, '5': 1, '10': 'bitratePadding'},
    {'1': 'packets_out_of_order', '3': 19, '4': 1, '5': 13, '10': 'packetsOutOfOrder'},
    {'1': 'frames', '3': 20, '4': 1, '5': 13, '10': 'frames'},
    {'1': 'frame_rate', '3': 21, '4': 1, '5': 1, '10': 'frameRate'},
    {'1': 'jitter_current', '3': 22, '4': 1, '5': 1, '10': 'jitterCurrent'},
    {'1': 'jitter_max', '3': 23, '4': 1, '5': 1, '10': 'jitterMax'},
    {'1': 'gap_histogram', '3': 24, '4': 3, '5': 11, '6': '.livekit.RTPStats.GapHistogramEntry', '10': 'gapHistogram'},
    {'1': 'nacks', '3': 25, '4': 1, '5': 13, '10': 'nacks'},
    {'1': 'nack_acks', '3': 37, '4': 1, '5': 13, '10': 'nackAcks'},
    {'1': 'nack_misses', '3': 26, '4': 1, '5': 13, '10': 'nackMisses'},
    {'1': 'nack_repeated', '3': 38, '4': 1, '5': 13, '10': 'nackRepeated'},
    {'1': 'plis', '3': 27, '4': 1, '5': 13, '10': 'plis'},
    {'1': 'last_pli', '3': 28, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastPli'},
    {'1': 'firs', '3': 29, '4': 1, '5': 13, '10': 'firs'},
    {'1': 'last_fir', '3': 30, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastFir'},
    {'1': 'rtt_current', '3': 31, '4': 1, '5': 13, '10': 'rttCurrent'},
    {'1': 'rtt_max', '3': 32, '4': 1, '5': 13, '10': 'rttMax'},
    {'1': 'key_frames', '3': 33, '4': 1, '5': 13, '10': 'keyFrames'},
    {'1': 'last_key_frame', '3': 34, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastKeyFrame'},
    {'1': 'layer_lock_plis', '3': 35, '4': 1, '5': 13, '10': 'layerLockPlis'},
    {'1': 'last_layer_lock_pli', '3': 36, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastLayerLockPli'},
    {'1': 'packet_drift', '3': 44, '4': 1, '5': 11, '6': '.livekit.RTPDrift', '10': 'packetDrift'},
    {'1': 'ntp_report_drift', '3': 45, '4': 1, '5': 11, '6': '.livekit.RTPDrift', '10': 'ntpReportDrift'},
    {'1': 'rebased_report_drift', '3': 46, '4': 1, '5': 11, '6': '.livekit.RTPDrift', '10': 'rebasedReportDrift'},
    {'1': 'received_report_drift', '3': 47, '4': 1, '5': 11, '6': '.livekit.RTPDrift', '10': 'receivedReportDrift'},
  ],
  '3': [RTPStats_GapHistogramEntry$json],
};

@$core.Deprecated('Use rTPStatsDescriptor instead')
const RTPStats_GapHistogramEntry$json = {
  '1': 'GapHistogramEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 13, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `RTPStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPStatsDescriptor =
    $convert.base64Decode('CghSVFBTdGF0cxI5CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
        'FtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
        'dGFtcFIHZW5kVGltZRIaCghkdXJhdGlvbhgDIAEoAVIIZHVyYXRpb24SGAoHcGFja2V0cxgEIA'
        'EoDVIHcGFja2V0cxIfCgtwYWNrZXRfcmF0ZRgFIAEoAVIKcGFja2V0UmF0ZRIUCgVieXRlcxgG'
        'IAEoBFIFYnl0ZXMSIQoMaGVhZGVyX2J5dGVzGCcgASgEUgtoZWFkZXJCeXRlcxIYCgdiaXRyYX'
        'RlGAcgASgBUgdiaXRyYXRlEiEKDHBhY2tldHNfbG9zdBgIIAEoDVILcGFja2V0c0xvc3QSKAoQ'
        'cGFja2V0X2xvc3NfcmF0ZRgJIAEoAVIOcGFja2V0TG9zc1JhdGUSNAoWcGFja2V0X2xvc3NfcG'
        'VyY2VudGFnZRgKIAEoAlIUcGFja2V0TG9zc1BlcmNlbnRhZ2USKwoRcGFja2V0c19kdXBsaWNh'
        'dGUYCyABKA1SEHBhY2tldHNEdXBsaWNhdGUSMgoVcGFja2V0X2R1cGxpY2F0ZV9yYXRlGAwgAS'
        'gBUhNwYWNrZXREdXBsaWNhdGVSYXRlEicKD2J5dGVzX2R1cGxpY2F0ZRgNIAEoBFIOYnl0ZXNE'
        'dXBsaWNhdGUSNAoWaGVhZGVyX2J5dGVzX2R1cGxpY2F0ZRgoIAEoBFIUaGVhZGVyQnl0ZXNEdX'
        'BsaWNhdGUSKwoRYml0cmF0ZV9kdXBsaWNhdGUYDiABKAFSEGJpdHJhdGVEdXBsaWNhdGUSJwoP'
        'cGFja2V0c19wYWRkaW5nGA8gASgNUg5wYWNrZXRzUGFkZGluZxIuChNwYWNrZXRfcGFkZGluZ1'
        '9yYXRlGBAgASgBUhFwYWNrZXRQYWRkaW5nUmF0ZRIjCg1ieXRlc19wYWRkaW5nGBEgASgEUgxi'
        'eXRlc1BhZGRpbmcSMAoUaGVhZGVyX2J5dGVzX3BhZGRpbmcYKSABKARSEmhlYWRlckJ5dGVzUG'
        'FkZGluZxInCg9iaXRyYXRlX3BhZGRpbmcYEiABKAFSDmJpdHJhdGVQYWRkaW5nEi8KFHBhY2tl'
        'dHNfb3V0X29mX29yZGVyGBMgASgNUhFwYWNrZXRzT3V0T2ZPcmRlchIWCgZmcmFtZXMYFCABKA'
        '1SBmZyYW1lcxIdCgpmcmFtZV9yYXRlGBUgASgBUglmcmFtZVJhdGUSJQoOaml0dGVyX2N1cnJl'
        'bnQYFiABKAFSDWppdHRlckN1cnJlbnQSHQoKaml0dGVyX21heBgXIAEoAVIJaml0dGVyTWF4Ek'
        'gKDWdhcF9oaXN0b2dyYW0YGCADKAsyIy5saXZla2l0LlJUUFN0YXRzLkdhcEhpc3RvZ3JhbUVu'
        'dHJ5UgxnYXBIaXN0b2dyYW0SFAoFbmFja3MYGSABKA1SBW5hY2tzEhsKCW5hY2tfYWNrcxglIA'
        'EoDVIIbmFja0Fja3MSHwoLbmFja19taXNzZXMYGiABKA1SCm5hY2tNaXNzZXMSIwoNbmFja19y'
        'ZXBlYXRlZBgmIAEoDVIMbmFja1JlcGVhdGVkEhIKBHBsaXMYGyABKA1SBHBsaXMSNQoIbGFzdF'
        '9wbGkYHCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdsYXN0UGxpEhIKBGZpcnMY'
        'HSABKA1SBGZpcnMSNQoIbGFzdF9maXIYHiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW'
        '1wUgdsYXN0RmlyEh8KC3J0dF9jdXJyZW50GB8gASgNUgpydHRDdXJyZW50EhcKB3J0dF9tYXgY'
        'ICABKA1SBnJ0dE1heBIdCgprZXlfZnJhbWVzGCEgASgNUglrZXlGcmFtZXMSQAoObGFzdF9rZX'
        'lfZnJhbWUYIiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxsYXN0S2V5RnJhbWUS'
        'JgoPbGF5ZXJfbG9ja19wbGlzGCMgASgNUg1sYXllckxvY2tQbGlzEkkKE2xhc3RfbGF5ZXJfbG'
        '9ja19wbGkYJCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhBsYXN0TGF5ZXJMb2Nr'
        'UGxpEjQKDHBhY2tldF9kcmlmdBgsIAEoCzIRLmxpdmVraXQuUlRQRHJpZnRSC3BhY2tldERyaW'
        'Z0EjsKEG50cF9yZXBvcnRfZHJpZnQYLSABKAsyES5saXZla2l0LlJUUERyaWZ0Ug5udHBSZXBv'
        'cnREcmlmdBJDChRyZWJhc2VkX3JlcG9ydF9kcmlmdBguIAEoCzIRLmxpdmVraXQuUlRQRHJpZn'
        'RSEnJlYmFzZWRSZXBvcnREcmlmdBJFChVyZWNlaXZlZF9yZXBvcnRfZHJpZnQYLyABKAsyES5s'
        'aXZla2l0LlJUUERyaWZ0UhNyZWNlaXZlZFJlcG9ydERyaWZ0Gj8KEUdhcEhpc3RvZ3JhbUVudH'
        'J5EhAKA2tleRgBIAEoBVIDa2V5EhQKBXZhbHVlGAIgASgNUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use rTCPSenderReportStateDescriptor instead')
const RTCPSenderReportState$json = {
  '1': 'RTCPSenderReportState',
  '2': [
    {'1': 'rtp_timestamp', '3': 1, '4': 1, '5': 13, '10': 'rtpTimestamp'},
    {'1': 'rtp_timestamp_ext', '3': 2, '4': 1, '5': 4, '10': 'rtpTimestampExt'},
    {'1': 'ntp_timestamp', '3': 3, '4': 1, '5': 4, '10': 'ntpTimestamp'},
    {'1': 'at', '3': 4, '4': 1, '5': 3, '10': 'at'},
    {'1': 'at_adjusted', '3': 5, '4': 1, '5': 3, '10': 'atAdjusted'},
    {'1': 'packets', '3': 6, '4': 1, '5': 13, '10': 'packets'},
    {'1': 'octets', '3': 7, '4': 1, '5': 4, '10': 'octets'},
  ],
};

/// Descriptor for `RTCPSenderReportState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTCPSenderReportStateDescriptor =
    $convert.base64Decode('ChVSVENQU2VuZGVyUmVwb3J0U3RhdGUSIwoNcnRwX3RpbWVzdGFtcBgBIAEoDVIMcnRwVGltZX'
        'N0YW1wEioKEXJ0cF90aW1lc3RhbXBfZXh0GAIgASgEUg9ydHBUaW1lc3RhbXBFeHQSIwoNbnRw'
        'X3RpbWVzdGFtcBgDIAEoBFIMbnRwVGltZXN0YW1wEg4KAmF0GAQgASgDUgJhdBIfCgthdF9hZG'
        'p1c3RlZBgFIAEoA1IKYXRBZGp1c3RlZBIYCgdwYWNrZXRzGAYgASgNUgdwYWNrZXRzEhYKBm9j'
        'dGV0cxgHIAEoBFIGb2N0ZXRz');

@$core.Deprecated('Use rTPForwarderStateDescriptor instead')
const RTPForwarderState$json = {
  '1': 'RTPForwarderState',
  '2': [
    {'1': 'started', '3': 1, '4': 1, '5': 8, '10': 'started'},
    {'1': 'reference_layer_spatial', '3': 2, '4': 1, '5': 5, '10': 'referenceLayerSpatial'},
    {'1': 'pre_start_time', '3': 3, '4': 1, '5': 3, '10': 'preStartTime'},
    {'1': 'ext_first_timestamp', '3': 4, '4': 1, '5': 4, '10': 'extFirstTimestamp'},
    {'1': 'dummy_start_timestamp_offset', '3': 5, '4': 1, '5': 4, '10': 'dummyStartTimestampOffset'},
    {'1': 'rtp_munger', '3': 6, '4': 1, '5': 11, '6': '.livekit.RTPMungerState', '10': 'rtpMunger'},
    {'1': 'vp8_munger', '3': 7, '4': 1, '5': 11, '6': '.livekit.VP8MungerState', '9': 0, '10': 'vp8Munger'},
    {
      '1': 'sender_report_state',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.livekit.RTCPSenderReportState',
      '10': 'senderReportState'
    },
  ],
  '8': [
    {'1': 'codec_munger'},
  ],
};

/// Descriptor for `RTPForwarderState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPForwarderStateDescriptor =
    $convert.base64Decode('ChFSVFBGb3J3YXJkZXJTdGF0ZRIYCgdzdGFydGVkGAEgASgIUgdzdGFydGVkEjYKF3JlZmVyZW'
        '5jZV9sYXllcl9zcGF0aWFsGAIgASgFUhVyZWZlcmVuY2VMYXllclNwYXRpYWwSJAoOcHJlX3N0'
        'YXJ0X3RpbWUYAyABKANSDHByZVN0YXJ0VGltZRIuChNleHRfZmlyc3RfdGltZXN0YW1wGAQgAS'
        'gEUhFleHRGaXJzdFRpbWVzdGFtcBI/ChxkdW1teV9zdGFydF90aW1lc3RhbXBfb2Zmc2V0GAUg'
        'ASgEUhlkdW1teVN0YXJ0VGltZXN0YW1wT2Zmc2V0EjYKCnJ0cF9tdW5nZXIYBiABKAsyFy5saX'
        'Zla2l0LlJUUE11bmdlclN0YXRlUglydHBNdW5nZXISOAoKdnA4X211bmdlchgHIAEoCzIXLmxp'
        'dmVraXQuVlA4TXVuZ2VyU3RhdGVIAFIJdnA4TXVuZ2VyEk4KE3NlbmRlcl9yZXBvcnRfc3RhdG'
        'UYCCADKAsyHi5saXZla2l0LlJUQ1BTZW5kZXJSZXBvcnRTdGF0ZVIRc2VuZGVyUmVwb3J0U3Rh'
        'dGVCDgoMY29kZWNfbXVuZ2Vy');

@$core.Deprecated('Use rTPMungerStateDescriptor instead')
const RTPMungerState$json = {
  '1': 'RTPMungerState',
  '2': [
    {'1': 'ext_last_sequence_number', '3': 1, '4': 1, '5': 4, '10': 'extLastSequenceNumber'},
    {'1': 'ext_second_last_sequence_number', '3': 2, '4': 1, '5': 4, '10': 'extSecondLastSequenceNumber'},
    {'1': 'ext_last_timestamp', '3': 3, '4': 1, '5': 4, '10': 'extLastTimestamp'},
    {'1': 'ext_second_last_timestamp', '3': 4, '4': 1, '5': 4, '10': 'extSecondLastTimestamp'},
    {'1': 'last_marker', '3': 5, '4': 1, '5': 8, '10': 'lastMarker'},
    {'1': 'second_last_marker', '3': 6, '4': 1, '5': 8, '10': 'secondLastMarker'},
  ],
};

/// Descriptor for `RTPMungerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rTPMungerStateDescriptor =
    $convert.base64Decode('Cg5SVFBNdW5nZXJTdGF0ZRI3ChhleHRfbGFzdF9zZXF1ZW5jZV9udW1iZXIYASABKARSFWV4dE'
        'xhc3RTZXF1ZW5jZU51bWJlchJECh9leHRfc2Vjb25kX2xhc3Rfc2VxdWVuY2VfbnVtYmVyGAIg'
        'ASgEUhtleHRTZWNvbmRMYXN0U2VxdWVuY2VOdW1iZXISLAoSZXh0X2xhc3RfdGltZXN0YW1wGA'
        'MgASgEUhBleHRMYXN0VGltZXN0YW1wEjkKGWV4dF9zZWNvbmRfbGFzdF90aW1lc3RhbXAYBCAB'
        'KARSFmV4dFNlY29uZExhc3RUaW1lc3RhbXASHwoLbGFzdF9tYXJrZXIYBSABKAhSCmxhc3RNYX'
        'JrZXISLAoSc2Vjb25kX2xhc3RfbWFya2VyGAYgASgIUhBzZWNvbmRMYXN0TWFya2Vy');

@$core.Deprecated('Use vP8MungerStateDescriptor instead')
const VP8MungerState$json = {
  '1': 'VP8MungerState',
  '2': [
    {'1': 'ext_last_picture_id', '3': 1, '4': 1, '5': 5, '10': 'extLastPictureId'},
    {'1': 'picture_id_used', '3': 2, '4': 1, '5': 8, '10': 'pictureIdUsed'},
    {'1': 'last_tl0_pic_idx', '3': 3, '4': 1, '5': 13, '10': 'lastTl0PicIdx'},
    {'1': 'tl0_pic_idx_used', '3': 4, '4': 1, '5': 8, '10': 'tl0PicIdxUsed'},
    {'1': 'tid_used', '3': 5, '4': 1, '5': 8, '10': 'tidUsed'},
    {'1': 'last_key_idx', '3': 6, '4': 1, '5': 13, '10': 'lastKeyIdx'},
    {'1': 'key_idx_used', '3': 7, '4': 1, '5': 8, '10': 'keyIdxUsed'},
  ],
};

/// Descriptor for `VP8MungerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vP8MungerStateDescriptor =
    $convert.base64Decode('Cg5WUDhNdW5nZXJTdGF0ZRItChNleHRfbGFzdF9waWN0dXJlX2lkGAEgASgFUhBleHRMYXN0UG'
        'ljdHVyZUlkEiYKD3BpY3R1cmVfaWRfdXNlZBgCIAEoCFINcGljdHVyZUlkVXNlZBInChBsYXN0'
        'X3RsMF9waWNfaWR4GAMgASgNUg1sYXN0VGwwUGljSWR4EicKEHRsMF9waWNfaWR4X3VzZWQYBC'
        'ABKAhSDXRsMFBpY0lkeFVzZWQSGQoIdGlkX3VzZWQYBSABKAhSB3RpZFVzZWQSIAoMbGFzdF9r'
        'ZXlfaWR4GAYgASgNUgpsYXN0S2V5SWR4EiAKDGtleV9pZHhfdXNlZBgHIAEoCFIKa2V5SWR4VX'
        'NlZA==');

@$core.Deprecated('Use timedVersionDescriptor instead')
const TimedVersion$json = {
  '1': 'TimedVersion',
  '2': [
    {'1': 'unix_micro', '3': 1, '4': 1, '5': 3, '10': 'unixMicro'},
    {'1': 'ticks', '3': 2, '4': 1, '5': 5, '10': 'ticks'},
  ],
};

/// Descriptor for `TimedVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timedVersionDescriptor =
    $convert.base64Decode('CgxUaW1lZFZlcnNpb24SHQoKdW5peF9taWNybxgBIAEoA1IJdW5peE1pY3JvEhQKBXRpY2tzGA'
        'IgASgFUgV0aWNrcw==');

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream$json = {
  '1': 'DataStream',
  '3': [
    DataStream_TextHeader$json,
    DataStream_ByteHeader$json,
    DataStream_Header$json,
    DataStream_Chunk$json,
    DataStream_Trailer$json
  ],
  '4': [DataStream_OperationType$json],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_TextHeader$json = {
  '1': 'TextHeader',
  '2': [
    {'1': 'operation_type', '3': 1, '4': 1, '5': 14, '6': '.livekit.DataStream.OperationType', '10': 'operationType'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'reply_to_stream_id', '3': 3, '4': 1, '5': 9, '10': 'replyToStreamId'},
    {'1': 'attached_stream_ids', '3': 4, '4': 3, '5': 9, '10': 'attachedStreamIds'},
    {'1': 'generated', '3': 5, '4': 1, '5': 8, '10': 'generated'},
  ],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_ByteHeader$json = {
  '1': 'ByteHeader',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_Header$json = {
  '1': 'Header',
  '2': [
    {'1': 'stream_id', '3': 1, '4': 1, '5': 9, '10': 'streamId'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'topic', '3': 3, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'mime_type', '3': 4, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'total_length', '3': 5, '4': 1, '5': 4, '9': 1, '10': 'totalLength', '17': true},
    {
      '1': 'encryption_type',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.livekit.Encryption.Type',
      '8': {'3': true},
      '10': 'encryptionType',
    },
    {'1': 'attributes', '3': 8, '4': 3, '5': 11, '6': '.livekit.DataStream.Header.AttributesEntry', '10': 'attributes'},
    {'1': 'text_header', '3': 9, '4': 1, '5': 11, '6': '.livekit.DataStream.TextHeader', '9': 0, '10': 'textHeader'},
    {'1': 'byte_header', '3': 10, '4': 1, '5': 11, '6': '.livekit.DataStream.ByteHeader', '9': 0, '10': 'byteHeader'},
  ],
  '3': [DataStream_Header_AttributesEntry$json],
  '8': [
    {'1': 'content_header'},
    {'1': '_total_length'},
  ],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_Header_AttributesEntry$json = {
  '1': 'AttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_Chunk$json = {
  '1': 'Chunk',
  '2': [
    {'1': 'stream_id', '3': 1, '4': 1, '5': 9, '10': 'streamId'},
    {'1': 'chunk_index', '3': 2, '4': 1, '5': 4, '10': 'chunkIndex'},
    {'1': 'content', '3': 3, '4': 1, '5': 12, '10': 'content'},
    {'1': 'version', '3': 4, '4': 1, '5': 5, '10': 'version'},
    {
      '1': 'iv',
      '3': 5,
      '4': 1,
      '5': 12,
      '8': {'3': true},
      '9': 0,
      '10': 'iv',
      '17': true,
    },
  ],
  '8': [
    {'1': '_iv'},
  ],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_Trailer$json = {
  '1': 'Trailer',
  '2': [
    {'1': 'stream_id', '3': 1, '4': 1, '5': 9, '10': 'streamId'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {
      '1': 'attributes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.DataStream.Trailer.AttributesEntry',
      '10': 'attributes'
    },
  ],
  '3': [DataStream_Trailer_AttributesEntry$json],
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_Trailer_AttributesEntry$json = {
  '1': 'AttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use dataStreamDescriptor instead')
const DataStream_OperationType$json = {
  '1': 'OperationType',
  '2': [
    {'1': 'CREATE', '2': 0},
    {'1': 'UPDATE', '2': 1},
    {'1': 'DELETE', '2': 2},
    {'1': 'REACTION', '2': 3},
  ],
};

/// Descriptor for `DataStream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataStreamDescriptor =
    $convert.base64Decode('CgpEYXRhU3RyZWFtGusBCgpUZXh0SGVhZGVyEkgKDm9wZXJhdGlvbl90eXBlGAEgASgOMiEubG'
        'l2ZWtpdC5EYXRhU3RyZWFtLk9wZXJhdGlvblR5cGVSDW9wZXJhdGlvblR5cGUSGAoHdmVyc2lv'
        'bhgCIAEoBVIHdmVyc2lvbhIrChJyZXBseV90b19zdHJlYW1faWQYAyABKAlSD3JlcGx5VG9TdH'
        'JlYW1JZBIuChNhdHRhY2hlZF9zdHJlYW1faWRzGAQgAygJUhFhdHRhY2hlZFN0cmVhbUlkcxIc'
        'CglnZW5lcmF0ZWQYBSABKAhSCWdlbmVyYXRlZBogCgpCeXRlSGVhZGVyEhIKBG5hbWUYASABKA'
        'lSBG5hbWUamQQKBkhlYWRlchIbCglzdHJlYW1faWQYASABKAlSCHN0cmVhbUlkEhwKCXRpbWVz'
        'dGFtcBgCIAEoA1IJdGltZXN0YW1wEhQKBXRvcGljGAMgASgJUgV0b3BpYxIbCgltaW1lX3R5cG'
        'UYBCABKAlSCG1pbWVUeXBlEiYKDHRvdGFsX2xlbmd0aBgFIAEoBEgBUgt0b3RhbExlbmd0aIgB'
        'ARJFCg9lbmNyeXB0aW9uX3R5cGUYByABKA4yGC5saXZla2l0LkVuY3J5cHRpb24uVHlwZUICGA'
        'FSDmVuY3J5cHRpb25UeXBlEkoKCmF0dHJpYnV0ZXMYCCADKAsyKi5saXZla2l0LkRhdGFTdHJl'
        'YW0uSGVhZGVyLkF0dHJpYnV0ZXNFbnRyeVIKYXR0cmlidXRlcxJBCgt0ZXh0X2hlYWRlchgJIA'
        'EoCzIeLmxpdmVraXQuRGF0YVN0cmVhbS5UZXh0SGVhZGVySABSCnRleHRIZWFkZXISQQoLYnl0'
        'ZV9oZWFkZXIYCiABKAsyHi5saXZla2l0LkRhdGFTdHJlYW0uQnl0ZUhlYWRlckgAUgpieXRlSG'
        'VhZGVyGj0KD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEo'
        'CVIFdmFsdWU6AjgBQhAKDmNvbnRlbnRfaGVhZGVyQg8KDV90b3RhbF9sZW5ndGgamQEKBUNodW'
        '5rEhsKCXN0cmVhbV9pZBgBIAEoCVIIc3RyZWFtSWQSHwoLY2h1bmtfaW5kZXgYAiABKARSCmNo'
        'dW5rSW5kZXgSGAoHY29udGVudBgDIAEoDFIHY29udGVudBIYCgd2ZXJzaW9uGAQgASgFUgd2ZX'
        'JzaW9uEhcKAml2GAUgASgMQgIYAUgAUgJpdogBAUIFCgNfaXYaygEKB1RyYWlsZXISGwoJc3Ry'
        'ZWFtX2lkGAEgASgJUghzdHJlYW1JZBIWCgZyZWFzb24YAiABKAlSBnJlYXNvbhJLCgphdHRyaW'
        'J1dGVzGAMgAygLMisubGl2ZWtpdC5EYXRhU3RyZWFtLlRyYWlsZXIuQXR0cmlidXRlc0VudHJ5'
        'UgphdHRyaWJ1dGVzGj0KD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YW'
        'x1ZRgCIAEoCVIFdmFsdWU6AjgBIkEKDU9wZXJhdGlvblR5cGUSCgoGQ1JFQVRFEAASCgoGVVBE'
        'QVRFEAESCgoGREVMRVRFEAISDAoIUkVBQ1RJT04QAw==');

@$core.Deprecated('Use filterParamsDescriptor instead')
const FilterParams$json = {
  '1': 'FilterParams',
  '2': [
    {'1': 'include_events', '3': 1, '4': 3, '5': 9, '10': 'includeEvents'},
    {'1': 'exclude_events', '3': 2, '4': 3, '5': 9, '10': 'excludeEvents'},
  ],
};

/// Descriptor for `FilterParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterParamsDescriptor =
    $convert.base64Decode('CgxGaWx0ZXJQYXJhbXMSJQoOaW5jbHVkZV9ldmVudHMYASADKAlSDWluY2x1ZGVFdmVudHMSJQ'
        'oOZXhjbHVkZV9ldmVudHMYAiADKAlSDWV4Y2x1ZGVFdmVudHM=');

@$core.Deprecated('Use webhookConfigDescriptor instead')
const WebhookConfig$json = {
  '1': 'WebhookConfig',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'signing_key', '3': 2, '4': 1, '5': 9, '10': 'signingKey'},
    {'1': 'filter_params', '3': 3, '4': 1, '5': 11, '6': '.livekit.FilterParams', '10': 'filterParams'},
  ],
};

/// Descriptor for `WebhookConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webhookConfigDescriptor =
    $convert.base64Decode('Cg1XZWJob29rQ29uZmlnEhAKA3VybBgBIAEoCVIDdXJsEh8KC3NpZ25pbmdfa2V5GAIgASgJUg'
        'pzaWduaW5nS2V5EjoKDWZpbHRlcl9wYXJhbXMYAyABKAsyFS5saXZla2l0LkZpbHRlclBhcmFt'
        'c1IMZmlsdGVyUGFyYW1z');

@$core.Deprecated('Use subscribedAudioCodecDescriptor instead')
const SubscribedAudioCodec$json = {
  '1': 'SubscribedAudioCodec',
  '2': [
    {'1': 'codec', '3': 1, '4': 1, '5': 9, '10': 'codec'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SubscribedAudioCodec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedAudioCodecDescriptor =
    $convert.base64Decode('ChRTdWJzY3JpYmVkQXVkaW9Db2RlYxIUCgVjb2RlYxgBIAEoCVIFY29kZWMSGAoHZW5hYmxlZB'
        'gCIAEoCFIHZW5hYmxlZA==');
