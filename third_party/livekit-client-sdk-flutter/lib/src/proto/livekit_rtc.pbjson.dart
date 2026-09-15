// This is a generated file - do not edit.
//
// Generated from livekit_rtc.proto.

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

@$core.Deprecated('Use signalTargetDescriptor instead')
const SignalTarget$json = {
  '1': 'SignalTarget',
  '2': [
    {'1': 'PUBLISHER', '2': 0},
    {'1': 'SUBSCRIBER', '2': 1},
  ],
};

/// Descriptor for `SignalTarget`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List signalTargetDescriptor =
    $convert.base64Decode('CgxTaWduYWxUYXJnZXQSDQoJUFVCTElTSEVSEAASDgoKU1VCU0NSSUJFUhAB');

@$core.Deprecated('Use streamStateDescriptor instead')
const StreamState$json = {
  '1': 'StreamState',
  '2': [
    {'1': 'ACTIVE', '2': 0},
    {'1': 'PAUSED', '2': 1},
  ],
};

/// Descriptor for `StreamState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List streamStateDescriptor =
    $convert.base64Decode('CgtTdHJlYW1TdGF0ZRIKCgZBQ1RJVkUQABIKCgZQQVVTRUQQAQ==');

@$core.Deprecated('Use candidateProtocolDescriptor instead')
const CandidateProtocol$json = {
  '1': 'CandidateProtocol',
  '2': [
    {'1': 'UDP', '2': 0},
    {'1': 'TCP', '2': 1},
    {'1': 'TLS', '2': 2},
  ],
};

/// Descriptor for `CandidateProtocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List candidateProtocolDescriptor =
    $convert.base64Decode('ChFDYW5kaWRhdGVQcm90b2NvbBIHCgNVRFAQABIHCgNUQ1AQARIHCgNUTFMQAg==');

@$core.Deprecated('Use signalRequestDescriptor instead')
const SignalRequest$json = {
  '1': 'SignalRequest',
  '2': [
    {'1': 'offer', '3': 1, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '9': 0, '10': 'offer'},
    {'1': 'answer', '3': 2, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '9': 0, '10': 'answer'},
    {'1': 'trickle', '3': 3, '4': 1, '5': 11, '6': '.livekit.TrickleRequest', '9': 0, '10': 'trickle'},
    {'1': 'add_track', '3': 4, '4': 1, '5': 11, '6': '.livekit.AddTrackRequest', '9': 0, '10': 'addTrack'},
    {'1': 'mute', '3': 5, '4': 1, '5': 11, '6': '.livekit.MuteTrackRequest', '9': 0, '10': 'mute'},
    {'1': 'subscription', '3': 6, '4': 1, '5': 11, '6': '.livekit.UpdateSubscription', '9': 0, '10': 'subscription'},
    {'1': 'track_setting', '3': 7, '4': 1, '5': 11, '6': '.livekit.UpdateTrackSettings', '9': 0, '10': 'trackSetting'},
    {'1': 'leave', '3': 8, '4': 1, '5': 11, '6': '.livekit.LeaveRequest', '9': 0, '10': 'leave'},
    {
      '1': 'update_layers',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateVideoLayers',
      '8': {'3': true},
      '9': 0,
      '10': 'updateLayers',
    },
    {
      '1': 'subscription_permission',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermission',
      '9': 0,
      '10': 'subscriptionPermission'
    },
    {'1': 'sync_state', '3': 12, '4': 1, '5': 11, '6': '.livekit.SyncState', '9': 0, '10': 'syncState'},
    {'1': 'simulate', '3': 13, '4': 1, '5': 11, '6': '.livekit.SimulateScenario', '9': 0, '10': 'simulate'},
    {'1': 'ping', '3': 14, '4': 1, '5': 3, '9': 0, '10': 'ping'},
    {
      '1': 'update_metadata',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateParticipantMetadata',
      '9': 0,
      '10': 'updateMetadata'
    },
    {'1': 'ping_req', '3': 16, '4': 1, '5': 11, '6': '.livekit.Ping', '9': 0, '10': 'pingReq'},
    {
      '1': 'update_audio_track',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateLocalAudioTrack',
      '9': 0,
      '10': 'updateAudioTrack'
    },
    {
      '1': 'update_video_track',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateLocalVideoTrack',
      '9': 0,
      '10': 'updateVideoTrack'
    },
    {
      '1': 'publish_data_track_request',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.livekit.PublishDataTrackRequest',
      '9': 0,
      '10': 'publishDataTrackRequest'
    },
    {
      '1': 'unpublish_data_track_request',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.livekit.UnpublishDataTrackRequest',
      '9': 0,
      '10': 'unpublishDataTrackRequest'
    },
    {
      '1': 'update_data_subscription',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateDataSubscription',
      '9': 0,
      '10': 'updateDataSubscription'
    },
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `SignalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalRequestDescriptor =
    $convert.base64Decode('Cg1TaWduYWxSZXF1ZXN0EjMKBW9mZmVyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcH'
        'Rpb25IAFIFb2ZmZXISNQoGYW5zd2VyGAIgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRp'
        'b25IAFIGYW5zd2VyEjMKB3RyaWNrbGUYAyABKAsyFy5saXZla2l0LlRyaWNrbGVSZXF1ZXN0SA'
        'BSB3RyaWNrbGUSNwoJYWRkX3RyYWNrGAQgASgLMhgubGl2ZWtpdC5BZGRUcmFja1JlcXVlc3RI'
        'AFIIYWRkVHJhY2sSLwoEbXV0ZRgFIAEoCzIZLmxpdmVraXQuTXV0ZVRyYWNrUmVxdWVzdEgAUg'
        'RtdXRlEkEKDHN1YnNjcmlwdGlvbhgGIAEoCzIbLmxpdmVraXQuVXBkYXRlU3Vic2NyaXB0aW9u'
        'SABSDHN1YnNjcmlwdGlvbhJDCg10cmFja19zZXR0aW5nGAcgASgLMhwubGl2ZWtpdC5VcGRhdG'
        'VUcmFja1NldHRpbmdzSABSDHRyYWNrU2V0dGluZxItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQu'
        'TGVhdmVSZXF1ZXN0SABSBWxlYXZlEkUKDXVwZGF0ZV9sYXllcnMYCiABKAsyGi5saXZla2l0Ll'
        'VwZGF0ZVZpZGVvTGF5ZXJzQgIYAUgAUgx1cGRhdGVMYXllcnMSWgoXc3Vic2NyaXB0aW9uX3Bl'
        'cm1pc3Npb24YCyABKAsyHy5saXZla2l0LlN1YnNjcmlwdGlvblBlcm1pc3Npb25IAFIWc3Vic2'
        'NyaXB0aW9uUGVybWlzc2lvbhIzCgpzeW5jX3N0YXRlGAwgASgLMhIubGl2ZWtpdC5TeW5jU3Rh'
        'dGVIAFIJc3luY1N0YXRlEjcKCHNpbXVsYXRlGA0gASgLMhkubGl2ZWtpdC5TaW11bGF0ZVNjZW'
        '5hcmlvSABSCHNpbXVsYXRlEhQKBHBpbmcYDiABKANIAFIEcGluZxJNCg91cGRhdGVfbWV0YWRh'
        'dGEYDyABKAsyIi5saXZla2l0LlVwZGF0ZVBhcnRpY2lwYW50TWV0YWRhdGFIAFIOdXBkYXRlTW'
        'V0YWRhdGESKgoIcGluZ19yZXEYECABKAsyDS5saXZla2l0LlBpbmdIAFIHcGluZ1JlcRJOChJ1'
        'cGRhdGVfYXVkaW9fdHJhY2sYESABKAsyHi5saXZla2l0LlVwZGF0ZUxvY2FsQXVkaW9UcmFja0'
        'gAUhB1cGRhdGVBdWRpb1RyYWNrEk4KEnVwZGF0ZV92aWRlb190cmFjaxgSIAEoCzIeLmxpdmVr'
        'aXQuVXBkYXRlTG9jYWxWaWRlb1RyYWNrSABSEHVwZGF0ZVZpZGVvVHJhY2sSXwoacHVibGlzaF'
        '9kYXRhX3RyYWNrX3JlcXVlc3QYEyABKAsyIC5saXZla2l0LlB1Ymxpc2hEYXRhVHJhY2tSZXF1'
        'ZXN0SABSF3B1Ymxpc2hEYXRhVHJhY2tSZXF1ZXN0EmUKHHVucHVibGlzaF9kYXRhX3RyYWNrX3'
        'JlcXVlc3QYFCABKAsyIi5saXZla2l0LlVucHVibGlzaERhdGFUcmFja1JlcXVlc3RIAFIZdW5w'
        'dWJsaXNoRGF0YVRyYWNrUmVxdWVzdBJbChh1cGRhdGVfZGF0YV9zdWJzY3JpcHRpb24YFSABKA'
        'syHy5saXZla2l0LlVwZGF0ZURhdGFTdWJzY3JpcHRpb25IAFIWdXBkYXRlRGF0YVN1YnNjcmlw'
        'dGlvbkIJCgdtZXNzYWdl');

@$core.Deprecated('Use signalResponseDescriptor instead')
const SignalResponse$json = {
  '1': 'SignalResponse',
  '2': [
    {'1': 'join', '3': 1, '4': 1, '5': 11, '6': '.livekit.JoinResponse', '9': 0, '10': 'join'},
    {'1': 'answer', '3': 2, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '9': 0, '10': 'answer'},
    {'1': 'offer', '3': 3, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '9': 0, '10': 'offer'},
    {'1': 'trickle', '3': 4, '4': 1, '5': 11, '6': '.livekit.TrickleRequest', '9': 0, '10': 'trickle'},
    {'1': 'update', '3': 5, '4': 1, '5': 11, '6': '.livekit.ParticipantUpdate', '9': 0, '10': 'update'},
    {
      '1': 'track_published',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackPublishedResponse',
      '9': 0,
      '10': 'trackPublished'
    },
    {'1': 'leave', '3': 8, '4': 1, '5': 11, '6': '.livekit.LeaveRequest', '9': 0, '10': 'leave'},
    {'1': 'mute', '3': 9, '4': 1, '5': 11, '6': '.livekit.MuteTrackRequest', '9': 0, '10': 'mute'},
    {
      '1': 'speakers_changed',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.SpeakersChanged',
      '9': 0,
      '10': 'speakersChanged'
    },
    {'1': 'room_update', '3': 11, '4': 1, '5': 11, '6': '.livekit.RoomUpdate', '9': 0, '10': 'roomUpdate'},
    {
      '1': 'connection_quality',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.livekit.ConnectionQualityUpdate',
      '9': 0,
      '10': 'connectionQuality'
    },
    {
      '1': 'stream_state_update',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.livekit.StreamStateUpdate',
      '9': 0,
      '10': 'streamStateUpdate'
    },
    {
      '1': 'subscribed_quality_update',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscribedQualityUpdate',
      '9': 0,
      '10': 'subscribedQualityUpdate'
    },
    {
      '1': 'subscription_permission_update',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionPermissionUpdate',
      '9': 0,
      '10': 'subscriptionPermissionUpdate'
    },
    {'1': 'refresh_token', '3': 16, '4': 1, '5': 9, '9': 0, '10': 'refreshToken'},
    {
      '1': 'track_unpublished',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackUnpublishedResponse',
      '9': 0,
      '10': 'trackUnpublished'
    },
    {'1': 'pong', '3': 18, '4': 1, '5': 3, '9': 0, '10': 'pong'},
    {'1': 'reconnect', '3': 19, '4': 1, '5': 11, '6': '.livekit.ReconnectResponse', '9': 0, '10': 'reconnect'},
    {'1': 'pong_resp', '3': 20, '4': 1, '5': 11, '6': '.livekit.Pong', '9': 0, '10': 'pongResp'},
    {
      '1': 'subscription_response',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscriptionResponse',
      '9': 0,
      '10': 'subscriptionResponse'
    },
    {
      '1': 'request_response',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.livekit.RequestResponse',
      '9': 0,
      '10': 'requestResponse'
    },
    {
      '1': 'track_subscribed',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.livekit.TrackSubscribed',
      '9': 0,
      '10': 'trackSubscribed'
    },
    {'1': 'room_moved', '3': 24, '4': 1, '5': 11, '6': '.livekit.RoomMovedResponse', '9': 0, '10': 'roomMoved'},
    {
      '1': 'media_sections_requirement',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.livekit.MediaSectionsRequirement',
      '9': 0,
      '10': 'mediaSectionsRequirement'
    },
    {
      '1': 'subscribed_audio_codec_update',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.livekit.SubscribedAudioCodecUpdate',
      '9': 0,
      '10': 'subscribedAudioCodecUpdate'
    },
    {
      '1': 'publish_data_track_response',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.livekit.PublishDataTrackResponse',
      '9': 0,
      '10': 'publishDataTrackResponse'
    },
    {
      '1': 'unpublish_data_track_response',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.livekit.UnpublishDataTrackResponse',
      '9': 0,
      '10': 'unpublishDataTrackResponse'
    },
    {
      '1': 'data_track_subscriber_handles',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.livekit.DataTrackSubscriberHandles',
      '9': 0,
      '10': 'dataTrackSubscriberHandles'
    },
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `SignalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalResponseDescriptor =
    $convert.base64Decode('Cg5TaWduYWxSZXNwb25zZRIrCgRqb2luGAEgASgLMhUubGl2ZWtpdC5Kb2luUmVzcG9uc2VIAF'
        'IEam9pbhI1CgZhbnN3ZXIYAiABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgZh'
        'bnN3ZXISMwoFb2ZmZXIYAyABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvbkgAUgVvZm'
        'ZlchIzCgd0cmlja2xlGAQgASgLMhcubGl2ZWtpdC5Ucmlja2xlUmVxdWVzdEgAUgd0cmlja2xl'
        'EjQKBnVwZGF0ZRgFIAEoCzIaLmxpdmVraXQuUGFydGljaXBhbnRVcGRhdGVIAFIGdXBkYXRlEk'
        'oKD3RyYWNrX3B1Ymxpc2hlZBgGIAEoCzIfLmxpdmVraXQuVHJhY2tQdWJsaXNoZWRSZXNwb25z'
        'ZUgAUg50cmFja1B1Ymxpc2hlZBItCgVsZWF2ZRgIIAEoCzIVLmxpdmVraXQuTGVhdmVSZXF1ZX'
        'N0SABSBWxlYXZlEi8KBG11dGUYCSABKAsyGS5saXZla2l0Lk11dGVUcmFja1JlcXVlc3RIAFIE'
        'bXV0ZRJFChBzcGVha2Vyc19jaGFuZ2VkGAogASgLMhgubGl2ZWtpdC5TcGVha2Vyc0NoYW5nZW'
        'RIAFIPc3BlYWtlcnNDaGFuZ2VkEjYKC3Jvb21fdXBkYXRlGAsgASgLMhMubGl2ZWtpdC5Sb29t'
        'VXBkYXRlSABSCnJvb21VcGRhdGUSUQoSY29ubmVjdGlvbl9xdWFsaXR5GAwgASgLMiAubGl2ZW'
        'tpdC5Db25uZWN0aW9uUXVhbGl0eVVwZGF0ZUgAUhFjb25uZWN0aW9uUXVhbGl0eRJMChNzdHJl'
        'YW1fc3RhdGVfdXBkYXRlGA0gASgLMhoubGl2ZWtpdC5TdHJlYW1TdGF0ZVVwZGF0ZUgAUhFzdH'
        'JlYW1TdGF0ZVVwZGF0ZRJeChlzdWJzY3JpYmVkX3F1YWxpdHlfdXBkYXRlGA4gASgLMiAubGl2'
        'ZWtpdC5TdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZUgAUhdzdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZR'
        'JtCh5zdWJzY3JpcHRpb25fcGVybWlzc2lvbl91cGRhdGUYDyABKAsyJS5saXZla2l0LlN1YnNj'
        'cmlwdGlvblBlcm1pc3Npb25VcGRhdGVIAFIcc3Vic2NyaXB0aW9uUGVybWlzc2lvblVwZGF0ZR'
        'IlCg1yZWZyZXNoX3Rva2VuGBAgASgJSABSDHJlZnJlc2hUb2tlbhJQChF0cmFja191bnB1Ymxp'
        'c2hlZBgRIAEoCzIhLmxpdmVraXQuVHJhY2tVbnB1Ymxpc2hlZFJlc3BvbnNlSABSEHRyYWNrVW'
        '5wdWJsaXNoZWQSFAoEcG9uZxgSIAEoA0gAUgRwb25nEjoKCXJlY29ubmVjdBgTIAEoCzIaLmxp'
        'dmVraXQuUmVjb25uZWN0UmVzcG9uc2VIAFIJcmVjb25uZWN0EiwKCXBvbmdfcmVzcBgUIAEoCz'
        'INLmxpdmVraXQuUG9uZ0gAUghwb25nUmVzcBJUChVzdWJzY3JpcHRpb25fcmVzcG9uc2UYFSAB'
        'KAsyHS5saXZla2l0LlN1YnNjcmlwdGlvblJlc3BvbnNlSABSFHN1YnNjcmlwdGlvblJlc3Bvbn'
        'NlEkUKEHJlcXVlc3RfcmVzcG9uc2UYFiABKAsyGC5saXZla2l0LlJlcXVlc3RSZXNwb25zZUgA'
        'Ug9yZXF1ZXN0UmVzcG9uc2USRQoQdHJhY2tfc3Vic2NyaWJlZBgXIAEoCzIYLmxpdmVraXQuVH'
        'JhY2tTdWJzY3JpYmVkSABSD3RyYWNrU3Vic2NyaWJlZBI7Cgpyb29tX21vdmVkGBggASgLMhou'
        'bGl2ZWtpdC5Sb29tTW92ZWRSZXNwb25zZUgAUglyb29tTW92ZWQSYQoabWVkaWFfc2VjdGlvbn'
        'NfcmVxdWlyZW1lbnQYGSABKAsyIS5saXZla2l0Lk1lZGlhU2VjdGlvbnNSZXF1aXJlbWVudEgA'
        'UhhtZWRpYVNlY3Rpb25zUmVxdWlyZW1lbnQSaAodc3Vic2NyaWJlZF9hdWRpb19jb2RlY191cG'
        'RhdGUYGiABKAsyIy5saXZla2l0LlN1YnNjcmliZWRBdWRpb0NvZGVjVXBkYXRlSABSGnN1YnNj'
        'cmliZWRBdWRpb0NvZGVjVXBkYXRlEmIKG3B1Ymxpc2hfZGF0YV90cmFja19yZXNwb25zZRgbIA'
        'EoCzIhLmxpdmVraXQuUHVibGlzaERhdGFUcmFja1Jlc3BvbnNlSABSGHB1Ymxpc2hEYXRhVHJh'
        'Y2tSZXNwb25zZRJoCh11bnB1Ymxpc2hfZGF0YV90cmFja19yZXNwb25zZRgcIAEoCzIjLmxpdm'
        'VraXQuVW5wdWJsaXNoRGF0YVRyYWNrUmVzcG9uc2VIAFIadW5wdWJsaXNoRGF0YVRyYWNrUmVz'
        'cG9uc2USaAodZGF0YV90cmFja19zdWJzY3JpYmVyX2hhbmRsZXMYHSABKAsyIy5saXZla2l0Lk'
        'RhdGFUcmFja1N1YnNjcmliZXJIYW5kbGVzSABSGmRhdGFUcmFja1N1YnNjcmliZXJIYW5kbGVz'
        'QgkKB21lc3NhZ2U=');

@$core.Deprecated('Use simulcastCodecDescriptor instead')
const SimulcastCodec$json = {
  '1': 'SimulcastCodec',
  '2': [
    {'1': 'codec', '3': 1, '4': 1, '5': 9, '10': 'codec'},
    {'1': 'cid', '3': 2, '4': 1, '5': 9, '10': 'cid'},
    {'1': 'layers', '3': 4, '4': 3, '5': 11, '6': '.livekit.VideoLayer', '10': 'layers'},
    {'1': 'video_layer_mode', '3': 5, '4': 1, '5': 14, '6': '.livekit.VideoLayer.Mode', '10': 'videoLayerMode'},
  ],
};

/// Descriptor for `SimulcastCodec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulcastCodecDescriptor =
    $convert.base64Decode('Cg5TaW11bGNhc3RDb2RlYxIUCgVjb2RlYxgBIAEoCVIFY29kZWMSEAoDY2lkGAIgASgJUgNjaW'
        'QSKwoGbGF5ZXJzGAQgAygLMhMubGl2ZWtpdC5WaWRlb0xheWVyUgZsYXllcnMSQgoQdmlkZW9f'
        'bGF5ZXJfbW9kZRgFIAEoDjIYLmxpdmVraXQuVmlkZW9MYXllci5Nb2RlUg52aWRlb0xheWVyTW'
        '9kZQ==');

@$core.Deprecated('Use addTrackRequestDescriptor instead')
const AddTrackRequest$json = {
  '1': 'AddTrackRequest',
  '2': [
    {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 3, '4': 1, '5': 14, '6': '.livekit.TrackType', '10': 'type'},
    {'1': 'width', '3': 4, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 5, '4': 1, '5': 13, '10': 'height'},
    {'1': 'muted', '3': 6, '4': 1, '5': 8, '10': 'muted'},
    {
      '1': 'disable_dtx',
      '3': 7,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'disableDtx',
    },
    {'1': 'source', '3': 8, '4': 1, '5': 14, '6': '.livekit.TrackSource', '10': 'source'},
    {'1': 'layers', '3': 9, '4': 3, '5': 11, '6': '.livekit.VideoLayer', '10': 'layers'},
    {'1': 'simulcast_codecs', '3': 10, '4': 3, '5': 11, '6': '.livekit.SimulcastCodec', '10': 'simulcastCodecs'},
    {'1': 'sid', '3': 11, '4': 1, '5': 9, '10': 'sid'},
    {
      '1': 'stereo',
      '3': 12,
      '4': 1,
      '5': 8,
      '8': {'3': true},
      '10': 'stereo',
    },
    {'1': 'disable_red', '3': 13, '4': 1, '5': 8, '10': 'disableRed'},
    {'1': 'encryption', '3': 14, '4': 1, '5': 14, '6': '.livekit.Encryption.Type', '10': 'encryption'},
    {'1': 'stream', '3': 15, '4': 1, '5': 9, '10': 'stream'},
    {
      '1': 'backup_codec_policy',
      '3': 16,
      '4': 1,
      '5': 14,
      '6': '.livekit.BackupCodecPolicy',
      '10': 'backupCodecPolicy'
    },
    {'1': 'audio_features', '3': 17, '4': 3, '5': 14, '6': '.livekit.AudioTrackFeature', '10': 'audioFeatures'},
  ],
};

/// Descriptor for `AddTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackRequestDescriptor =
    $convert.base64Decode('Cg9BZGRUcmFja1JlcXVlc3QSEAoDY2lkGAEgASgJUgNjaWQSEgoEbmFtZRgCIAEoCVIEbmFtZR'
        'ImCgR0eXBlGAMgASgOMhIubGl2ZWtpdC5UcmFja1R5cGVSBHR5cGUSFAoFd2lkdGgYBCABKA1S'
        'BXdpZHRoEhYKBmhlaWdodBgFIAEoDVIGaGVpZ2h0EhQKBW11dGVkGAYgASgIUgVtdXRlZBIjCg'
        'tkaXNhYmxlX2R0eBgHIAEoCEICGAFSCmRpc2FibGVEdHgSLAoGc291cmNlGAggASgOMhQubGl2'
        'ZWtpdC5UcmFja1NvdXJjZVIGc291cmNlEisKBmxheWVycxgJIAMoCzITLmxpdmVraXQuVmlkZW'
        '9MYXllclIGbGF5ZXJzEkIKEHNpbXVsY2FzdF9jb2RlY3MYCiADKAsyFy5saXZla2l0LlNpbXVs'
        'Y2FzdENvZGVjUg9zaW11bGNhc3RDb2RlY3MSEAoDc2lkGAsgASgJUgNzaWQSGgoGc3RlcmVvGA'
        'wgASgIQgIYAVIGc3RlcmVvEh8KC2Rpc2FibGVfcmVkGA0gASgIUgpkaXNhYmxlUmVkEjgKCmVu'
        'Y3J5cHRpb24YDiABKA4yGC5saXZla2l0LkVuY3J5cHRpb24uVHlwZVIKZW5jcnlwdGlvbhIWCg'
        'ZzdHJlYW0YDyABKAlSBnN0cmVhbRJKChNiYWNrdXBfY29kZWNfcG9saWN5GBAgASgOMhoubGl2'
        'ZWtpdC5CYWNrdXBDb2RlY1BvbGljeVIRYmFja3VwQ29kZWNQb2xpY3kSQQoOYXVkaW9fZmVhdH'
        'VyZXMYESADKA4yGi5saXZla2l0LkF1ZGlvVHJhY2tGZWF0dXJlUg1hdWRpb0ZlYXR1cmVz');

@$core.Deprecated('Use publishDataTrackRequestDescriptor instead')
const PublishDataTrackRequest$json = {
  '1': 'PublishDataTrackRequest',
  '2': [
    {'1': 'pub_handle', '3': 1, '4': 1, '5': 13, '10': 'pubHandle'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'encryption', '3': 3, '4': 1, '5': 14, '6': '.livekit.Encryption.Type', '10': 'encryption'},
  ],
};

/// Descriptor for `PublishDataTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDataTrackRequestDescriptor =
    $convert.base64Decode('ChdQdWJsaXNoRGF0YVRyYWNrUmVxdWVzdBIdCgpwdWJfaGFuZGxlGAEgASgNUglwdWJIYW5kbG'
        'USEgoEbmFtZRgCIAEoCVIEbmFtZRI4CgplbmNyeXB0aW9uGAMgASgOMhgubGl2ZWtpdC5FbmNy'
        'eXB0aW9uLlR5cGVSCmVuY3J5cHRpb24=');

@$core.Deprecated('Use publishDataTrackResponseDescriptor instead')
const PublishDataTrackResponse$json = {
  '1': 'PublishDataTrackResponse',
  '2': [
    {'1': 'info', '3': 1, '4': 1, '5': 11, '6': '.livekit.DataTrackInfo', '10': 'info'},
  ],
};

/// Descriptor for `PublishDataTrackResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDataTrackResponseDescriptor =
    $convert.base64Decode('ChhQdWJsaXNoRGF0YVRyYWNrUmVzcG9uc2USKgoEaW5mbxgBIAEoCzIWLmxpdmVraXQuRGF0YV'
        'RyYWNrSW5mb1IEaW5mbw==');

@$core.Deprecated('Use unpublishDataTrackRequestDescriptor instead')
const UnpublishDataTrackRequest$json = {
  '1': 'UnpublishDataTrackRequest',
  '2': [
    {'1': 'pub_handle', '3': 1, '4': 1, '5': 13, '10': 'pubHandle'},
  ],
};

/// Descriptor for `UnpublishDataTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unpublishDataTrackRequestDescriptor =
    $convert.base64Decode('ChlVbnB1Ymxpc2hEYXRhVHJhY2tSZXF1ZXN0Eh0KCnB1Yl9oYW5kbGUYASABKA1SCXB1Ykhhbm'
        'RsZQ==');

@$core.Deprecated('Use unpublishDataTrackResponseDescriptor instead')
const UnpublishDataTrackResponse$json = {
  '1': 'UnpublishDataTrackResponse',
  '2': [
    {'1': 'info', '3': 1, '4': 1, '5': 11, '6': '.livekit.DataTrackInfo', '10': 'info'},
  ],
};

/// Descriptor for `UnpublishDataTrackResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unpublishDataTrackResponseDescriptor =
    $convert.base64Decode('ChpVbnB1Ymxpc2hEYXRhVHJhY2tSZXNwb25zZRIqCgRpbmZvGAEgASgLMhYubGl2ZWtpdC5EYX'
        'RhVHJhY2tJbmZvUgRpbmZv');

@$core.Deprecated('Use dataTrackSubscriberHandlesDescriptor instead')
const DataTrackSubscriberHandles$json = {
  '1': 'DataTrackSubscriberHandles',
  '2': [
    {
      '1': 'sub_handles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.livekit.DataTrackSubscriberHandles.SubHandlesEntry',
      '10': 'subHandles'
    },
  ],
  '3': [DataTrackSubscriberHandles_PublishedDataTrack$json, DataTrackSubscriberHandles_SubHandlesEntry$json],
};

@$core.Deprecated('Use dataTrackSubscriberHandlesDescriptor instead')
const DataTrackSubscriberHandles_PublishedDataTrack$json = {
  '1': 'PublishedDataTrack',
  '2': [
    {'1': 'publisher_identity', '3': 1, '4': 1, '5': 9, '10': 'publisherIdentity'},
    {'1': 'publisher_sid', '3': 2, '4': 1, '5': 9, '10': 'publisherSid'},
    {'1': 'track_sid', '3': 3, '4': 1, '5': 9, '10': 'trackSid'},
  ],
};

@$core.Deprecated('Use dataTrackSubscriberHandlesDescriptor instead')
const DataTrackSubscriberHandles_SubHandlesEntry$json = {
  '1': 'SubHandlesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 13, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.DataTrackSubscriberHandles.PublishedDataTrack',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `DataTrackSubscriberHandles`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataTrackSubscriberHandlesDescriptor =
    $convert.base64Decode('ChpEYXRhVHJhY2tTdWJzY3JpYmVySGFuZGxlcxJUCgtzdWJfaGFuZGxlcxgBIAMoCzIzLmxpdm'
        'VraXQuRGF0YVRyYWNrU3Vic2NyaWJlckhhbmRsZXMuU3ViSGFuZGxlc0VudHJ5UgpzdWJIYW5k'
        'bGVzGoUBChJQdWJsaXNoZWREYXRhVHJhY2sSLQoScHVibGlzaGVyX2lkZW50aXR5GAEgASgJUh'
        'FwdWJsaXNoZXJJZGVudGl0eRIjCg1wdWJsaXNoZXJfc2lkGAIgASgJUgxwdWJsaXNoZXJTaWQS'
        'GwoJdHJhY2tfc2lkGAMgASgJUgh0cmFja1NpZBp1Cg9TdWJIYW5kbGVzRW50cnkSEAoDa2V5GA'
        'EgASgNUgNrZXkSTAoFdmFsdWUYAiABKAsyNi5saXZla2l0LkRhdGFUcmFja1N1YnNjcmliZXJI'
        'YW5kbGVzLlB1Ymxpc2hlZERhdGFUcmFja1IFdmFsdWU6AjgB');

@$core.Deprecated('Use trickleRequestDescriptor instead')
const TrickleRequest$json = {
  '1': 'TrickleRequest',
  '2': [
    {'1': 'candidateInit', '3': 1, '4': 1, '5': 9, '10': 'candidateInit'},
    {'1': 'target', '3': 2, '4': 1, '5': 14, '6': '.livekit.SignalTarget', '10': 'target'},
    {'1': 'final', '3': 3, '4': 1, '5': 8, '10': 'final'},
  ],
};

/// Descriptor for `TrickleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trickleRequestDescriptor =
    $convert.base64Decode('Cg5Ucmlja2xlUmVxdWVzdBIkCg1jYW5kaWRhdGVJbml0GAEgASgJUg1jYW5kaWRhdGVJbml0Ei'
        '0KBnRhcmdldBgCIAEoDjIVLmxpdmVraXQuU2lnbmFsVGFyZ2V0UgZ0YXJnZXQSFAoFZmluYWwY'
        'AyABKAhSBWZpbmFs');

@$core.Deprecated('Use muteTrackRequestDescriptor instead')
const MuteTrackRequest$json = {
  '1': 'MuteTrackRequest',
  '2': [
    {'1': 'sid', '3': 1, '4': 1, '5': 9, '10': 'sid'},
    {'1': 'muted', '3': 2, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `MuteTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List muteTrackRequestDescriptor =
    $convert.base64Decode('ChBNdXRlVHJhY2tSZXF1ZXN0EhAKA3NpZBgBIAEoCVIDc2lkEhQKBW11dGVkGAIgASgIUgVtdX'
        'RlZA==');

@$core.Deprecated('Use joinResponseDescriptor instead')
const JoinResponse$json = {
  '1': 'JoinResponse',
  '2': [
    {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
    {'1': 'participant', '3': 2, '4': 1, '5': 11, '6': '.livekit.ParticipantInfo', '10': 'participant'},
    {'1': 'other_participants', '3': 3, '4': 3, '5': 11, '6': '.livekit.ParticipantInfo', '10': 'otherParticipants'},
    {'1': 'server_version', '3': 4, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'ice_servers', '3': 5, '4': 3, '5': 11, '6': '.livekit.ICEServer', '10': 'iceServers'},
    {'1': 'subscriber_primary', '3': 6, '4': 1, '5': 8, '10': 'subscriberPrimary'},
    {'1': 'alternative_url', '3': 7, '4': 1, '5': 9, '10': 'alternativeUrl'},
    {
      '1': 'client_configuration',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.ClientConfiguration',
      '10': 'clientConfiguration'
    },
    {'1': 'server_region', '3': 9, '4': 1, '5': 9, '10': 'serverRegion'},
    {'1': 'ping_timeout', '3': 10, '4': 1, '5': 5, '10': 'pingTimeout'},
    {'1': 'ping_interval', '3': 11, '4': 1, '5': 5, '10': 'pingInterval'},
    {'1': 'server_info', '3': 12, '4': 1, '5': 11, '6': '.livekit.ServerInfo', '10': 'serverInfo'},
    {'1': 'sif_trailer', '3': 13, '4': 1, '5': 12, '10': 'sifTrailer'},
    {'1': 'enabled_publish_codecs', '3': 14, '4': 3, '5': 11, '6': '.livekit.Codec', '10': 'enabledPublishCodecs'},
    {'1': 'fast_publish', '3': 15, '4': 1, '5': 8, '10': 'fastPublish'},
  ],
};

/// Descriptor for `JoinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinResponseDescriptor =
    $convert.base64Decode('CgxKb2luUmVzcG9uc2USIQoEcm9vbRgBIAEoCzINLmxpdmVraXQuUm9vbVIEcm9vbRI6CgtwYX'
        'J0aWNpcGFudBgCIAEoCzIYLmxpdmVraXQuUGFydGljaXBhbnRJbmZvUgtwYXJ0aWNpcGFudBJH'
        'ChJvdGhlcl9wYXJ0aWNpcGFudHMYAyADKAsyGC5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IRb3'
        'RoZXJQYXJ0aWNpcGFudHMSJQoOc2VydmVyX3ZlcnNpb24YBCABKAlSDXNlcnZlclZlcnNpb24S'
        'MwoLaWNlX3NlcnZlcnMYBSADKAsyEi5saXZla2l0LklDRVNlcnZlclIKaWNlU2VydmVycxItCh'
        'JzdWJzY3JpYmVyX3ByaW1hcnkYBiABKAhSEXN1YnNjcmliZXJQcmltYXJ5EicKD2FsdGVybmF0'
        'aXZlX3VybBgHIAEoCVIOYWx0ZXJuYXRpdmVVcmwSTwoUY2xpZW50X2NvbmZpZ3VyYXRpb24YCC'
        'ABKAsyHC5saXZla2l0LkNsaWVudENvbmZpZ3VyYXRpb25SE2NsaWVudENvbmZpZ3VyYXRpb24S'
        'IwoNc2VydmVyX3JlZ2lvbhgJIAEoCVIMc2VydmVyUmVnaW9uEiEKDHBpbmdfdGltZW91dBgKIA'
        'EoBVILcGluZ1RpbWVvdXQSIwoNcGluZ19pbnRlcnZhbBgLIAEoBVIMcGluZ0ludGVydmFsEjQK'
        'C3NlcnZlcl9pbmZvGAwgASgLMhMubGl2ZWtpdC5TZXJ2ZXJJbmZvUgpzZXJ2ZXJJbmZvEh8KC3'
        'NpZl90cmFpbGVyGA0gASgMUgpzaWZUcmFpbGVyEkQKFmVuYWJsZWRfcHVibGlzaF9jb2RlY3MY'
        'DiADKAsyDi5saXZla2l0LkNvZGVjUhRlbmFibGVkUHVibGlzaENvZGVjcxIhCgxmYXN0X3B1Ym'
        'xpc2gYDyABKAhSC2Zhc3RQdWJsaXNo');

@$core.Deprecated('Use reconnectResponseDescriptor instead')
const ReconnectResponse$json = {
  '1': 'ReconnectResponse',
  '2': [
    {'1': 'ice_servers', '3': 1, '4': 3, '5': 11, '6': '.livekit.ICEServer', '10': 'iceServers'},
    {
      '1': 'client_configuration',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.ClientConfiguration',
      '10': 'clientConfiguration'
    },
    {'1': 'server_info', '3': 3, '4': 1, '5': 11, '6': '.livekit.ServerInfo', '10': 'serverInfo'},
    {'1': 'last_message_seq', '3': 4, '4': 1, '5': 13, '10': 'lastMessageSeq'},
  ],
};

/// Descriptor for `ReconnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reconnectResponseDescriptor =
    $convert.base64Decode('ChFSZWNvbm5lY3RSZXNwb25zZRIzCgtpY2Vfc2VydmVycxgBIAMoCzISLmxpdmVraXQuSUNFU2'
        'VydmVyUgppY2VTZXJ2ZXJzEk8KFGNsaWVudF9jb25maWd1cmF0aW9uGAIgASgLMhwubGl2ZWtp'
        'dC5DbGllbnRDb25maWd1cmF0aW9uUhNjbGllbnRDb25maWd1cmF0aW9uEjQKC3NlcnZlcl9pbm'
        'ZvGAMgASgLMhMubGl2ZWtpdC5TZXJ2ZXJJbmZvUgpzZXJ2ZXJJbmZvEigKEGxhc3RfbWVzc2Fn'
        'ZV9zZXEYBCABKA1SDmxhc3RNZXNzYWdlU2Vx');

@$core.Deprecated('Use trackPublishedResponseDescriptor instead')
const TrackPublishedResponse$json = {
  '1': 'TrackPublishedResponse',
  '2': [
    {'1': 'cid', '3': 1, '4': 1, '5': 9, '10': 'cid'},
    {'1': 'track', '3': 2, '4': 1, '5': 11, '6': '.livekit.TrackInfo', '10': 'track'},
  ],
};

/// Descriptor for `TrackPublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPublishedResponseDescriptor =
    $convert.base64Decode('ChZUcmFja1B1Ymxpc2hlZFJlc3BvbnNlEhAKA2NpZBgBIAEoCVIDY2lkEigKBXRyYWNrGAIgAS'
        'gLMhIubGl2ZWtpdC5UcmFja0luZm9SBXRyYWNr');

@$core.Deprecated('Use trackUnpublishedResponseDescriptor instead')
const TrackUnpublishedResponse$json = {
  '1': 'TrackUnpublishedResponse',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
  ],
};

/// Descriptor for `TrackUnpublishedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackUnpublishedResponseDescriptor =
    $convert.base64Decode('ChhUcmFja1VucHVibGlzaGVkUmVzcG9uc2USGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZA'
        '==');

@$core.Deprecated('Use sessionDescriptionDescriptor instead')
const SessionDescription$json = {
  '1': 'SessionDescription',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'sdp', '3': 2, '4': 1, '5': 9, '10': 'sdp'},
    {'1': 'id', '3': 3, '4': 1, '5': 13, '10': 'id'},
    {
      '1': 'mid_to_track_id',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.SessionDescription.MidToTrackIdEntry',
      '10': 'midToTrackId'
    },
  ],
  '3': [SessionDescription_MidToTrackIdEntry$json],
};

@$core.Deprecated('Use sessionDescriptionDescriptor instead')
const SessionDescription_MidToTrackIdEntry$json = {
  '1': 'MidToTrackIdEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SessionDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptionDescriptor =
    $convert.base64Decode('ChJTZXNzaW9uRGVzY3JpcHRpb24SEgoEdHlwZRgBIAEoCVIEdHlwZRIQCgNzZHAYAiABKAlSA3'
        'NkcBIOCgJpZBgDIAEoDVICaWQSVAoPbWlkX3RvX3RyYWNrX2lkGAQgAygLMi0ubGl2ZWtpdC5T'
        'ZXNzaW9uRGVzY3JpcHRpb24uTWlkVG9UcmFja0lkRW50cnlSDG1pZFRvVHJhY2tJZBo/ChFNaW'
        'RUb1RyYWNrSWRFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6'
        'AjgB');

@$core.Deprecated('Use participantUpdateDescriptor instead')
const ParticipantUpdate$json = {
  '1': 'ParticipantUpdate',
  '2': [
    {'1': 'participants', '3': 1, '4': 3, '5': 11, '6': '.livekit.ParticipantInfo', '10': 'participants'},
  ],
};

/// Descriptor for `ParticipantUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantUpdateDescriptor =
    $convert.base64Decode('ChFQYXJ0aWNpcGFudFVwZGF0ZRI8CgxwYXJ0aWNpcGFudHMYASADKAsyGC5saXZla2l0LlBhcn'
        'RpY2lwYW50SW5mb1IMcGFydGljaXBhbnRz');

@$core.Deprecated('Use updateSubscriptionDescriptor instead')
const UpdateSubscription$json = {
  '1': 'UpdateSubscription',
  '2': [
    {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    {'1': 'subscribe', '3': 2, '4': 1, '5': 8, '10': 'subscribe'},
    {'1': 'participant_tracks', '3': 3, '4': 3, '5': 11, '6': '.livekit.ParticipantTracks', '10': 'participantTracks'},
  ],
};

/// Descriptor for `UpdateSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSubscriptionDescriptor =
    $convert.base64Decode('ChJVcGRhdGVTdWJzY3JpcHRpb24SHQoKdHJhY2tfc2lkcxgBIAMoCVIJdHJhY2tTaWRzEhwKCX'
        'N1YnNjcmliZRgCIAEoCFIJc3Vic2NyaWJlEkkKEnBhcnRpY2lwYW50X3RyYWNrcxgDIAMoCzIa'
        'LmxpdmVraXQuUGFydGljaXBhbnRUcmFja3NSEXBhcnRpY2lwYW50VHJhY2tz');

@$core.Deprecated('Use updateDataSubscriptionDescriptor instead')
const UpdateDataSubscription$json = {
  '1': 'UpdateDataSubscription',
  '2': [
    {'1': 'updates', '3': 1, '4': 3, '5': 11, '6': '.livekit.UpdateDataSubscription.Update', '10': 'updates'},
  ],
  '3': [UpdateDataSubscription_Update$json],
};

@$core.Deprecated('Use updateDataSubscriptionDescriptor instead')
const UpdateDataSubscription_Update$json = {
  '1': 'Update',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'subscribe', '3': 2, '4': 1, '5': 8, '10': 'subscribe'},
    {'1': 'options', '3': 3, '4': 1, '5': 11, '6': '.livekit.DataTrackSubscriptionOptions', '10': 'options'},
  ],
};

/// Descriptor for `UpdateDataSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateDataSubscriptionDescriptor =
    $convert.base64Decode('ChZVcGRhdGVEYXRhU3Vic2NyaXB0aW9uEkAKB3VwZGF0ZXMYASADKAsyJi5saXZla2l0LlVwZG'
        'F0ZURhdGFTdWJzY3JpcHRpb24uVXBkYXRlUgd1cGRhdGVzGoQBCgZVcGRhdGUSGwoJdHJhY2tf'
        'c2lkGAEgASgJUgh0cmFja1NpZBIcCglzdWJzY3JpYmUYAiABKAhSCXN1YnNjcmliZRI/CgdvcH'
        'Rpb25zGAMgASgLMiUubGl2ZWtpdC5EYXRhVHJhY2tTdWJzY3JpcHRpb25PcHRpb25zUgdvcHRp'
        'b25z');

@$core.Deprecated('Use updateTrackSettingsDescriptor instead')
const UpdateTrackSettings$json = {
  '1': 'UpdateTrackSettings',
  '2': [
    {'1': 'track_sids', '3': 1, '4': 3, '5': 9, '10': 'trackSids'},
    {'1': 'disabled', '3': 3, '4': 1, '5': 8, '10': 'disabled'},
    {'1': 'quality', '3': 4, '4': 1, '5': 14, '6': '.livekit.VideoQuality', '10': 'quality'},
    {'1': 'width', '3': 5, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 6, '4': 1, '5': 13, '10': 'height'},
    {'1': 'fps', '3': 7, '4': 1, '5': 13, '10': 'fps'},
    {'1': 'priority', '3': 8, '4': 1, '5': 13, '10': 'priority'},
  ],
};

/// Descriptor for `UpdateTrackSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateTrackSettingsDescriptor =
    $convert.base64Decode('ChNVcGRhdGVUcmFja1NldHRpbmdzEh0KCnRyYWNrX3NpZHMYASADKAlSCXRyYWNrU2lkcxIaCg'
        'hkaXNhYmxlZBgDIAEoCFIIZGlzYWJsZWQSLwoHcXVhbGl0eRgEIAEoDjIVLmxpdmVraXQuVmlk'
        'ZW9RdWFsaXR5UgdxdWFsaXR5EhQKBXdpZHRoGAUgASgNUgV3aWR0aBIWCgZoZWlnaHQYBiABKA'
        '1SBmhlaWdodBIQCgNmcHMYByABKA1SA2ZwcxIaCghwcmlvcml0eRgIIAEoDVIIcHJpb3JpdHk=');

@$core.Deprecated('Use updateLocalAudioTrackDescriptor instead')
const UpdateLocalAudioTrack$json = {
  '1': 'UpdateLocalAudioTrack',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'features', '3': 2, '4': 3, '5': 14, '6': '.livekit.AudioTrackFeature', '10': 'features'},
  ],
};

/// Descriptor for `UpdateLocalAudioTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateLocalAudioTrackDescriptor =
    $convert.base64Decode('ChVVcGRhdGVMb2NhbEF1ZGlvVHJhY2sSGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZBI2Cg'
        'hmZWF0dXJlcxgCIAMoDjIaLmxpdmVraXQuQXVkaW9UcmFja0ZlYXR1cmVSCGZlYXR1cmVz');

@$core.Deprecated('Use updateLocalVideoTrackDescriptor instead')
const UpdateLocalVideoTrack$json = {
  '1': 'UpdateLocalVideoTrack',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'width', '3': 2, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 13, '10': 'height'},
  ],
};

/// Descriptor for `UpdateLocalVideoTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateLocalVideoTrackDescriptor =
    $convert.base64Decode('ChVVcGRhdGVMb2NhbFZpZGVvVHJhY2sSGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZBIUCg'
        'V3aWR0aBgCIAEoDVIFd2lkdGgSFgoGaGVpZ2h0GAMgASgNUgZoZWlnaHQ=');

@$core.Deprecated('Use leaveRequestDescriptor instead')
const LeaveRequest$json = {
  '1': 'LeaveRequest',
  '2': [
    {'1': 'can_reconnect', '3': 1, '4': 1, '5': 8, '10': 'canReconnect'},
    {'1': 'reason', '3': 2, '4': 1, '5': 14, '6': '.livekit.DisconnectReason', '10': 'reason'},
    {'1': 'action', '3': 3, '4': 1, '5': 14, '6': '.livekit.LeaveRequest.Action', '10': 'action'},
    {'1': 'regions', '3': 4, '4': 1, '5': 11, '6': '.livekit.RegionSettings', '10': 'regions'},
  ],
  '4': [LeaveRequest_Action$json],
};

@$core.Deprecated('Use leaveRequestDescriptor instead')
const LeaveRequest_Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'DISCONNECT', '2': 0},
    {'1': 'RESUME', '2': 1},
    {'1': 'RECONNECT', '2': 2},
  ],
};

/// Descriptor for `LeaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveRequestDescriptor =
    $convert.base64Decode('CgxMZWF2ZVJlcXVlc3QSIwoNY2FuX3JlY29ubmVjdBgBIAEoCFIMY2FuUmVjb25uZWN0EjEKBn'
        'JlYXNvbhgCIAEoDjIZLmxpdmVraXQuRGlzY29ubmVjdFJlYXNvblIGcmVhc29uEjQKBmFjdGlv'
        'bhgDIAEoDjIcLmxpdmVraXQuTGVhdmVSZXF1ZXN0LkFjdGlvblIGYWN0aW9uEjEKB3JlZ2lvbn'
        'MYBCABKAsyFy5saXZla2l0LlJlZ2lvblNldHRpbmdzUgdyZWdpb25zIjMKBkFjdGlvbhIOCgpE'
        'SVNDT05ORUNUEAASCgoGUkVTVU1FEAESDQoJUkVDT05ORUNUEAI=');

@$core.Deprecated('Use updateVideoLayersDescriptor instead')
const UpdateVideoLayers$json = {
  '1': 'UpdateVideoLayers',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'layers', '3': 2, '4': 3, '5': 11, '6': '.livekit.VideoLayer', '10': 'layers'},
  ],
  '7': {'3': true},
};

/// Descriptor for `UpdateVideoLayers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateVideoLayersDescriptor =
    $convert.base64Decode('ChFVcGRhdGVWaWRlb0xheWVycxIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEisKBmxheW'
        'VycxgCIAMoCzITLmxpdmVraXQuVmlkZW9MYXllclIGbGF5ZXJzOgIYAQ==');

@$core.Deprecated('Use updateParticipantMetadataDescriptor instead')
const UpdateParticipantMetadata$json = {
  '1': 'UpdateParticipantMetadata',
  '2': [
    {'1': 'metadata', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'metadata'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'attributes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekit.UpdateParticipantMetadata.AttributesEntry',
      '8': {},
      '10': 'attributes'
    },
    {'1': 'request_id', '3': 4, '4': 1, '5': 13, '10': 'requestId'},
  ],
  '3': [UpdateParticipantMetadata_AttributesEntry$json],
};

@$core.Deprecated('Use updateParticipantMetadataDescriptor instead')
const UpdateParticipantMetadata_AttributesEntry$json = {
  '1': 'AttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `UpdateParticipantMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateParticipantMetadataDescriptor =
    $convert.base64Decode('ChlVcGRhdGVQYXJ0aWNpcGFudE1ldGFkYXRhEkIKCG1ldGFkYXRhGAEgASgJQiaI7CwBkuwsHj'
        'xyZWRhY3RlZCAoe3sgLlNpemUgfX0gYnl0ZXMpPlIIbWV0YWRhdGESOgoEbmFtZRgCIAEoCUIm'
        'iOwsAZLsLB48cmVkYWN0ZWQgKHt7IC5TaXplIH19IGJ5dGVzKT5SBG5hbWUSegoKYXR0cmlidX'
        'RlcxgDIAMoCzIyLmxpdmVraXQuVXBkYXRlUGFydGljaXBhbnRNZXRhZGF0YS5BdHRyaWJ1dGVz'
        'RW50cnlCJojsLAGS7CwePHJlZGFjdGVkICh7eyAuU2l6ZSB9fSBieXRlcyk+UgphdHRyaWJ1dG'
        'VzEh0KCnJlcXVlc3RfaWQYBCABKA1SCXJlcXVlc3RJZBo9Cg9BdHRyaWJ1dGVzRW50cnkSEAoD'
        'a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use iCEServerDescriptor instead')
const ICEServer$json = {
  '1': 'ICEServer',
  '2': [
    {'1': 'urls', '3': 1, '4': 3, '5': 9, '10': 'urls'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'credential', '3': 3, '4': 1, '5': 9, '10': 'credential'},
  ],
};

/// Descriptor for `ICEServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iCEServerDescriptor =
    $convert.base64Decode('CglJQ0VTZXJ2ZXISEgoEdXJscxgBIAMoCVIEdXJscxIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm'
        '5hbWUSHgoKY3JlZGVudGlhbBgDIAEoCVIKY3JlZGVudGlhbA==');

@$core.Deprecated('Use speakersChangedDescriptor instead')
const SpeakersChanged$json = {
  '1': 'SpeakersChanged',
  '2': [
    {'1': 'speakers', '3': 1, '4': 3, '5': 11, '6': '.livekit.SpeakerInfo', '10': 'speakers'},
  ],
};

/// Descriptor for `SpeakersChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speakersChangedDescriptor =
    $convert.base64Decode('Cg9TcGVha2Vyc0NoYW5nZWQSMAoIc3BlYWtlcnMYASADKAsyFC5saXZla2l0LlNwZWFrZXJJbm'
        'ZvUghzcGVha2Vycw==');

@$core.Deprecated('Use roomUpdateDescriptor instead')
const RoomUpdate$json = {
  '1': 'RoomUpdate',
  '2': [
    {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
  ],
};

/// Descriptor for `RoomUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomUpdateDescriptor =
    $convert.base64Decode('CgpSb29tVXBkYXRlEiEKBHJvb20YASABKAsyDS5saXZla2l0LlJvb21SBHJvb20=');

@$core.Deprecated('Use connectionQualityInfoDescriptor instead')
const ConnectionQualityInfo$json = {
  '1': 'ConnectionQualityInfo',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'quality', '3': 2, '4': 1, '5': 14, '6': '.livekit.ConnectionQuality', '10': 'quality'},
    {'1': 'score', '3': 3, '4': 1, '5': 2, '10': 'score'},
  ],
};

/// Descriptor for `ConnectionQualityInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionQualityInfoDescriptor =
    $convert.base64Decode('ChVDb25uZWN0aW9uUXVhbGl0eUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aW'
        'NpcGFudFNpZBI0CgdxdWFsaXR5GAIgASgOMhoubGl2ZWtpdC5Db25uZWN0aW9uUXVhbGl0eVIH'
        'cXVhbGl0eRIUCgVzY29yZRgDIAEoAlIFc2NvcmU=');

@$core.Deprecated('Use connectionQualityUpdateDescriptor instead')
const ConnectionQualityUpdate$json = {
  '1': 'ConnectionQualityUpdate',
  '2': [
    {'1': 'updates', '3': 1, '4': 3, '5': 11, '6': '.livekit.ConnectionQualityInfo', '10': 'updates'},
  ],
};

/// Descriptor for `ConnectionQualityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionQualityUpdateDescriptor =
    $convert.base64Decode('ChdDb25uZWN0aW9uUXVhbGl0eVVwZGF0ZRI4Cgd1cGRhdGVzGAEgAygLMh4ubGl2ZWtpdC5Db2'
        '5uZWN0aW9uUXVhbGl0eUluZm9SB3VwZGF0ZXM=');

@$core.Deprecated('Use streamStateInfoDescriptor instead')
const StreamStateInfo$json = {
  '1': 'StreamStateInfo',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'state', '3': 3, '4': 1, '5': 14, '6': '.livekit.StreamState', '10': 'state'},
  ],
};

/// Descriptor for `StreamStateInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamStateInfoDescriptor =
    $convert.base64Decode('Cg9TdHJlYW1TdGF0ZUluZm8SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudF'
        'NpZBIbCgl0cmFja19zaWQYAiABKAlSCHRyYWNrU2lkEioKBXN0YXRlGAMgASgOMhQubGl2ZWtp'
        'dC5TdHJlYW1TdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use streamStateUpdateDescriptor instead')
const StreamStateUpdate$json = {
  '1': 'StreamStateUpdate',
  '2': [
    {'1': 'stream_states', '3': 1, '4': 3, '5': 11, '6': '.livekit.StreamStateInfo', '10': 'streamStates'},
  ],
};

/// Descriptor for `StreamStateUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamStateUpdateDescriptor =
    $convert.base64Decode('ChFTdHJlYW1TdGF0ZVVwZGF0ZRI9Cg1zdHJlYW1fc3RhdGVzGAEgAygLMhgubGl2ZWtpdC5TdH'
        'JlYW1TdGF0ZUluZm9SDHN0cmVhbVN0YXRlcw==');

@$core.Deprecated('Use subscribedQualityDescriptor instead')
const SubscribedQuality$json = {
  '1': 'SubscribedQuality',
  '2': [
    {'1': 'quality', '3': 1, '4': 1, '5': 14, '6': '.livekit.VideoQuality', '10': 'quality'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SubscribedQuality`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityDescriptor =
    $convert.base64Decode('ChFTdWJzY3JpYmVkUXVhbGl0eRIvCgdxdWFsaXR5GAEgASgOMhUubGl2ZWtpdC5WaWRlb1F1YW'
        'xpdHlSB3F1YWxpdHkSGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use subscribedCodecDescriptor instead')
const SubscribedCodec$json = {
  '1': 'SubscribedCodec',
  '2': [
    {'1': 'codec', '3': 1, '4': 1, '5': 9, '10': 'codec'},
    {'1': 'qualities', '3': 2, '4': 3, '5': 11, '6': '.livekit.SubscribedQuality', '10': 'qualities'},
  ],
};

/// Descriptor for `SubscribedCodec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedCodecDescriptor =
    $convert.base64Decode('Cg9TdWJzY3JpYmVkQ29kZWMSFAoFY29kZWMYASABKAlSBWNvZGVjEjgKCXF1YWxpdGllcxgCIA'
        'MoCzIaLmxpdmVraXQuU3Vic2NyaWJlZFF1YWxpdHlSCXF1YWxpdGllcw==');

@$core.Deprecated('Use subscribedQualityUpdateDescriptor instead')
const SubscribedQualityUpdate$json = {
  '1': 'SubscribedQualityUpdate',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {
      '1': 'subscribed_qualities',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedQuality',
      '8': {'3': true},
      '10': 'subscribedQualities',
    },
    {'1': 'subscribed_codecs', '3': 3, '4': 3, '5': 11, '6': '.livekit.SubscribedCodec', '10': 'subscribedCodecs'},
  ],
};

/// Descriptor for `SubscribedQualityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedQualityUpdateDescriptor =
    $convert.base64Decode('ChdTdWJzY3JpYmVkUXVhbGl0eVVwZGF0ZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEl'
        'EKFHN1YnNjcmliZWRfcXVhbGl0aWVzGAIgAygLMhoubGl2ZWtpdC5TdWJzY3JpYmVkUXVhbGl0'
        'eUICGAFSE3N1YnNjcmliZWRRdWFsaXRpZXMSRQoRc3Vic2NyaWJlZF9jb2RlY3MYAyADKAsyGC'
        '5saXZla2l0LlN1YnNjcmliZWRDb2RlY1IQc3Vic2NyaWJlZENvZGVjcw==');

@$core.Deprecated('Use subscribedAudioCodecUpdateDescriptor instead')
const SubscribedAudioCodecUpdate$json = {
  '1': 'SubscribedAudioCodecUpdate',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {
      '1': 'subscribed_audio_codecs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.livekit.SubscribedAudioCodec',
      '10': 'subscribedAudioCodecs'
    },
  ],
};

/// Descriptor for `SubscribedAudioCodecUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribedAudioCodecUpdateDescriptor =
    $convert.base64Decode('ChpTdWJzY3JpYmVkQXVkaW9Db2RlY1VwZGF0ZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2'
        'lkElUKF3N1YnNjcmliZWRfYXVkaW9fY29kZWNzGAIgAygLMh0ubGl2ZWtpdC5TdWJzY3JpYmVk'
        'QXVkaW9Db2RlY1IVc3Vic2NyaWJlZEF1ZGlvQ29kZWNz');

@$core.Deprecated('Use trackPermissionDescriptor instead')
const TrackPermission$json = {
  '1': 'TrackPermission',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'all_tracks', '3': 2, '4': 1, '5': 8, '10': 'allTracks'},
    {'1': 'track_sids', '3': 3, '4': 3, '5': 9, '10': 'trackSids'},
    {'1': 'participant_identity', '3': 4, '4': 1, '5': 9, '10': 'participantIdentity'},
  ],
};

/// Descriptor for `TrackPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackPermissionDescriptor =
    $convert.base64Decode('Cg9UcmFja1Blcm1pc3Npb24SJwoPcGFydGljaXBhbnRfc2lkGAEgASgJUg5wYXJ0aWNpcGFudF'
        'NpZBIdCgphbGxfdHJhY2tzGAIgASgIUglhbGxUcmFja3MSHQoKdHJhY2tfc2lkcxgDIAMoCVIJ'
        'dHJhY2tTaWRzEjEKFHBhcnRpY2lwYW50X2lkZW50aXR5GAQgASgJUhNwYXJ0aWNpcGFudElkZW'
        '50aXR5');

@$core.Deprecated('Use subscriptionPermissionDescriptor instead')
const SubscriptionPermission$json = {
  '1': 'SubscriptionPermission',
  '2': [
    {'1': 'all_participants', '3': 1, '4': 1, '5': 8, '10': 'allParticipants'},
    {'1': 'track_permissions', '3': 2, '4': 3, '5': 11, '6': '.livekit.TrackPermission', '10': 'trackPermissions'},
  ],
};

/// Descriptor for `SubscriptionPermission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionPermissionDescriptor =
    $convert.base64Decode('ChZTdWJzY3JpcHRpb25QZXJtaXNzaW9uEikKEGFsbF9wYXJ0aWNpcGFudHMYASABKAhSD2FsbF'
        'BhcnRpY2lwYW50cxJFChF0cmFja19wZXJtaXNzaW9ucxgCIAMoCzIYLmxpdmVraXQuVHJhY2tQ'
        'ZXJtaXNzaW9uUhB0cmFja1Blcm1pc3Npb25z');

@$core.Deprecated('Use subscriptionPermissionUpdateDescriptor instead')
const SubscriptionPermissionUpdate$json = {
  '1': 'SubscriptionPermissionUpdate',
  '2': [
    {'1': 'participant_sid', '3': 1, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'track_sid', '3': 2, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'allowed', '3': 3, '4': 1, '5': 8, '10': 'allowed'},
  ],
};

/// Descriptor for `SubscriptionPermissionUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionPermissionUpdateDescriptor =
    $convert.base64Decode('ChxTdWJzY3JpcHRpb25QZXJtaXNzaW9uVXBkYXRlEicKD3BhcnRpY2lwYW50X3NpZBgBIAEoCV'
        'IOcGFydGljaXBhbnRTaWQSGwoJdHJhY2tfc2lkGAIgASgJUgh0cmFja1NpZBIYCgdhbGxvd2Vk'
        'GAMgASgIUgdhbGxvd2Vk');

@$core.Deprecated('Use roomMovedResponseDescriptor instead')
const RoomMovedResponse$json = {
  '1': 'RoomMovedResponse',
  '2': [
    {'1': 'room', '3': 1, '4': 1, '5': 11, '6': '.livekit.Room', '10': 'room'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'participant', '3': 3, '4': 1, '5': 11, '6': '.livekit.ParticipantInfo', '10': 'participant'},
    {'1': 'other_participants', '3': 4, '4': 3, '5': 11, '6': '.livekit.ParticipantInfo', '10': 'otherParticipants'},
  ],
};

/// Descriptor for `RoomMovedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomMovedResponseDescriptor =
    $convert.base64Decode('ChFSb29tTW92ZWRSZXNwb25zZRIhCgRyb29tGAEgASgLMg0ubGl2ZWtpdC5Sb29tUgRyb29tEh'
        'QKBXRva2VuGAIgASgJUgV0b2tlbhI6CgtwYXJ0aWNpcGFudBgDIAEoCzIYLmxpdmVraXQuUGFy'
        'dGljaXBhbnRJbmZvUgtwYXJ0aWNpcGFudBJHChJvdGhlcl9wYXJ0aWNpcGFudHMYBCADKAsyGC'
        '5saXZla2l0LlBhcnRpY2lwYW50SW5mb1IRb3RoZXJQYXJ0aWNpcGFudHM=');

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState$json = {
  '1': 'SyncState',
  '2': [
    {'1': 'answer', '3': 1, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '10': 'answer'},
    {'1': 'subscription', '3': 2, '4': 1, '5': 11, '6': '.livekit.UpdateSubscription', '10': 'subscription'},
    {'1': 'publish_tracks', '3': 3, '4': 3, '5': 11, '6': '.livekit.TrackPublishedResponse', '10': 'publishTracks'},
    {'1': 'data_channels', '3': 4, '4': 3, '5': 11, '6': '.livekit.DataChannelInfo', '10': 'dataChannels'},
    {'1': 'offer', '3': 5, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '10': 'offer'},
    {'1': 'track_sids_disabled', '3': 6, '4': 3, '5': 9, '10': 'trackSidsDisabled'},
    {
      '1': 'datachannel_receive_states',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.livekit.DataChannelReceiveState',
      '10': 'datachannelReceiveStates'
    },
    {
      '1': 'publish_data_tracks',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.livekit.PublishDataTrackResponse',
      '10': 'publishDataTracks'
    },
  ],
};

/// Descriptor for `SyncState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStateDescriptor =
    $convert.base64Decode('CglTeW5jU3RhdGUSMwoGYW5zd2VyGAEgASgLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb2'
        '5SBmFuc3dlchI/CgxzdWJzY3JpcHRpb24YAiABKAsyGy5saXZla2l0LlVwZGF0ZVN1YnNjcmlw'
        'dGlvblIMc3Vic2NyaXB0aW9uEkYKDnB1Ymxpc2hfdHJhY2tzGAMgAygLMh8ubGl2ZWtpdC5Ucm'
        'Fja1B1Ymxpc2hlZFJlc3BvbnNlUg1wdWJsaXNoVHJhY2tzEj0KDWRhdGFfY2hhbm5lbHMYBCAD'
        'KAsyGC5saXZla2l0LkRhdGFDaGFubmVsSW5mb1IMZGF0YUNoYW5uZWxzEjEKBW9mZmVyGAUgAS'
        'gLMhsubGl2ZWtpdC5TZXNzaW9uRGVzY3JpcHRpb25SBW9mZmVyEi4KE3RyYWNrX3NpZHNfZGlz'
        'YWJsZWQYBiADKAlSEXRyYWNrU2lkc0Rpc2FibGVkEl4KGmRhdGFjaGFubmVsX3JlY2VpdmVfc3'
        'RhdGVzGAcgAygLMiAubGl2ZWtpdC5EYXRhQ2hhbm5lbFJlY2VpdmVTdGF0ZVIYZGF0YWNoYW5u'
        'ZWxSZWNlaXZlU3RhdGVzElEKE3B1Ymxpc2hfZGF0YV90cmFja3MYCCADKAsyIS5saXZla2l0Ll'
        'B1Ymxpc2hEYXRhVHJhY2tSZXNwb25zZVIRcHVibGlzaERhdGFUcmFja3M=');

@$core.Deprecated('Use dataChannelReceiveStateDescriptor instead')
const DataChannelReceiveState$json = {
  '1': 'DataChannelReceiveState',
  '2': [
    {'1': 'publisher_sid', '3': 1, '4': 1, '5': 9, '10': 'publisherSid'},
    {'1': 'last_seq', '3': 2, '4': 1, '5': 13, '10': 'lastSeq'},
  ],
};

/// Descriptor for `DataChannelReceiveState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataChannelReceiveStateDescriptor =
    $convert.base64Decode('ChdEYXRhQ2hhbm5lbFJlY2VpdmVTdGF0ZRIjCg1wdWJsaXNoZXJfc2lkGAEgASgJUgxwdWJsaX'
        'NoZXJTaWQSGQoIbGFzdF9zZXEYAiABKA1SB2xhc3RTZXE=');

@$core.Deprecated('Use dataChannelInfoDescriptor instead')
const DataChannelInfo$json = {
  '1': 'DataChannelInfo',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'id', '3': 2, '4': 1, '5': 13, '10': 'id'},
    {'1': 'target', '3': 3, '4': 1, '5': 14, '6': '.livekit.SignalTarget', '10': 'target'},
  ],
};

/// Descriptor for `DataChannelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataChannelInfoDescriptor =
    $convert.base64Decode('Cg9EYXRhQ2hhbm5lbEluZm8SFAoFbGFiZWwYASABKAlSBWxhYmVsEg4KAmlkGAIgASgNUgJpZB'
        'ItCgZ0YXJnZXQYAyABKA4yFS5saXZla2l0LlNpZ25hbFRhcmdldFIGdGFyZ2V0');

@$core.Deprecated('Use simulateScenarioDescriptor instead')
const SimulateScenario$json = {
  '1': 'SimulateScenario',
  '2': [
    {'1': 'speaker_update', '3': 1, '4': 1, '5': 5, '9': 0, '10': 'speakerUpdate'},
    {'1': 'node_failure', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'nodeFailure'},
    {'1': 'migration', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'migration'},
    {'1': 'server_leave', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'serverLeave'},
    {
      '1': 'switch_candidate_protocol',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.livekit.CandidateProtocol',
      '9': 0,
      '10': 'switchCandidateProtocol'
    },
    {'1': 'subscriber_bandwidth', '3': 6, '4': 1, '5': 3, '9': 0, '10': 'subscriberBandwidth'},
    {'1': 'disconnect_signal_on_resume', '3': 7, '4': 1, '5': 8, '9': 0, '10': 'disconnectSignalOnResume'},
    {
      '1': 'disconnect_signal_on_resume_no_messages',
      '3': 8,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'disconnectSignalOnResumeNoMessages'
    },
    {'1': 'leave_request_full_reconnect', '3': 9, '4': 1, '5': 8, '9': 0, '10': 'leaveRequestFullReconnect'},
  ],
  '8': [
    {'1': 'scenario'},
  ],
};

/// Descriptor for `SimulateScenario`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateScenarioDescriptor =
    $convert.base64Decode('ChBTaW11bGF0ZVNjZW5hcmlvEicKDnNwZWFrZXJfdXBkYXRlGAEgASgFSABSDXNwZWFrZXJVcG'
        'RhdGUSIwoMbm9kZV9mYWlsdXJlGAIgASgISABSC25vZGVGYWlsdXJlEh4KCW1pZ3JhdGlvbhgD'
        'IAEoCEgAUgltaWdyYXRpb24SIwoMc2VydmVyX2xlYXZlGAQgASgISABSC3NlcnZlckxlYXZlEl'
        'gKGXN3aXRjaF9jYW5kaWRhdGVfcHJvdG9jb2wYBSABKA4yGi5saXZla2l0LkNhbmRpZGF0ZVBy'
        'b3RvY29sSABSF3N3aXRjaENhbmRpZGF0ZVByb3RvY29sEjMKFHN1YnNjcmliZXJfYmFuZHdpZH'
        'RoGAYgASgDSABSE3N1YnNjcmliZXJCYW5kd2lkdGgSPwobZGlzY29ubmVjdF9zaWduYWxfb25f'
        'cmVzdW1lGAcgASgISABSGGRpc2Nvbm5lY3RTaWduYWxPblJlc3VtZRJVCidkaXNjb25uZWN0X3'
        'NpZ25hbF9vbl9yZXN1bWVfbm9fbWVzc2FnZXMYCCABKAhIAFIiZGlzY29ubmVjdFNpZ25hbE9u'
        'UmVzdW1lTm9NZXNzYWdlcxJBChxsZWF2ZV9yZXF1ZXN0X2Z1bGxfcmVjb25uZWN0GAkgASgISA'
        'BSGWxlYXZlUmVxdWVzdEZ1bGxSZWNvbm5lY3RCCgoIc2NlbmFyaW8=');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'rtt', '3': 2, '4': 1, '5': 3, '10': 'rtt'},
  ],
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor =
    $convert.base64Decode('CgRQaW5nEhwKCXRpbWVzdGFtcBgBIAEoA1IJdGltZXN0YW1wEhAKA3J0dBgCIAEoA1IDcnR0');

@$core.Deprecated('Use pongDescriptor instead')
const Pong$json = {
  '1': 'Pong',
  '2': [
    {'1': 'last_ping_timestamp', '3': 1, '4': 1, '5': 3, '10': 'lastPingTimestamp'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Pong`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pongDescriptor =
    $convert.base64Decode('CgRQb25nEi4KE2xhc3RfcGluZ190aW1lc3RhbXAYASABKANSEWxhc3RQaW5nVGltZXN0YW1wEh'
        'wKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1w');

@$core.Deprecated('Use regionSettingsDescriptor instead')
const RegionSettings$json = {
  '1': 'RegionSettings',
  '2': [
    {'1': 'regions', '3': 1, '4': 3, '5': 11, '6': '.livekit.RegionInfo', '10': 'regions'},
  ],
};

/// Descriptor for `RegionSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List regionSettingsDescriptor =
    $convert.base64Decode('Cg5SZWdpb25TZXR0aW5ncxItCgdyZWdpb25zGAEgAygLMhMubGl2ZWtpdC5SZWdpb25JbmZvUg'
        'dyZWdpb25z');

@$core.Deprecated('Use regionInfoDescriptor instead')
const RegionInfo$json = {
  '1': 'RegionInfo',
  '2': [
    {'1': 'region', '3': 1, '4': 1, '5': 9, '10': 'region'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {'1': 'distance', '3': 3, '4': 1, '5': 3, '10': 'distance'},
  ],
};

/// Descriptor for `RegionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List regionInfoDescriptor =
    $convert.base64Decode('CgpSZWdpb25JbmZvEhYKBnJlZ2lvbhgBIAEoCVIGcmVnaW9uEhAKA3VybBgCIAEoCVIDdXJsEh'
        'oKCGRpc3RhbmNlGAMgASgDUghkaXN0YW5jZQ==');

@$core.Deprecated('Use subscriptionResponseDescriptor instead')
const SubscriptionResponse$json = {
  '1': 'SubscriptionResponse',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
    {'1': 'err', '3': 2, '4': 1, '5': 14, '6': '.livekit.SubscriptionError', '10': 'err'},
  ],
};

/// Descriptor for `SubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionResponseDescriptor =
    $convert.base64Decode('ChRTdWJzY3JpcHRpb25SZXNwb25zZRIbCgl0cmFja19zaWQYASABKAlSCHRyYWNrU2lkEiwKA2'
        'VychgCIAEoDjIaLmxpdmVraXQuU3Vic2NyaXB0aW9uRXJyb3JSA2Vycg==');

@$core.Deprecated('Use requestResponseDescriptor instead')
const RequestResponse$json = {
  '1': 'RequestResponse',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 13, '10': 'requestId'},
    {'1': 'reason', '3': 2, '4': 1, '5': 14, '6': '.livekit.RequestResponse.Reason', '10': 'reason'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'trickle', '3': 4, '4': 1, '5': 11, '6': '.livekit.TrickleRequest', '9': 0, '10': 'trickle'},
    {'1': 'add_track', '3': 5, '4': 1, '5': 11, '6': '.livekit.AddTrackRequest', '9': 0, '10': 'addTrack'},
    {'1': 'mute', '3': 6, '4': 1, '5': 11, '6': '.livekit.MuteTrackRequest', '9': 0, '10': 'mute'},
    {
      '1': 'update_metadata',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateParticipantMetadata',
      '9': 0,
      '10': 'updateMetadata'
    },
    {
      '1': 'update_audio_track',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateLocalAudioTrack',
      '9': 0,
      '10': 'updateAudioTrack'
    },
    {
      '1': 'update_video_track',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.livekit.UpdateLocalVideoTrack',
      '9': 0,
      '10': 'updateVideoTrack'
    },
    {
      '1': 'publish_data_track',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.livekit.PublishDataTrackRequest',
      '9': 0,
      '10': 'publishDataTrack'
    },
    {
      '1': 'unpublish_data_track',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.livekit.UnpublishDataTrackRequest',
      '9': 0,
      '10': 'unpublishDataTrack'
    },
  ],
  '4': [RequestResponse_Reason$json],
  '8': [
    {'1': 'request'},
  ],
};

@$core.Deprecated('Use requestResponseDescriptor instead')
const RequestResponse_Reason$json = {
  '1': 'Reason',
  '2': [
    {'1': 'OK', '2': 0},
    {'1': 'NOT_FOUND', '2': 1},
    {'1': 'NOT_ALLOWED', '2': 2},
    {'1': 'LIMIT_EXCEEDED', '2': 3},
    {'1': 'QUEUED', '2': 4},
    {'1': 'UNSUPPORTED_TYPE', '2': 5},
    {'1': 'UNCLASSIFIED_ERROR', '2': 6},
    {'1': 'INVALID_HANDLE', '2': 7},
    {'1': 'INVALID_NAME', '2': 8},
    {'1': 'DUPLICATE_HANDLE', '2': 9},
    {'1': 'DUPLICATE_NAME', '2': 10},
  ],
};

/// Descriptor for `RequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestResponseDescriptor =
    $convert.base64Decode('Cg9SZXF1ZXN0UmVzcG9uc2USHQoKcmVxdWVzdF9pZBgBIAEoDVIJcmVxdWVzdElkEjcKBnJlYX'
        'NvbhgCIAEoDjIfLmxpdmVraXQuUmVxdWVzdFJlc3BvbnNlLlJlYXNvblIGcmVhc29uEhgKB21l'
        'c3NhZ2UYAyABKAlSB21lc3NhZ2USMwoHdHJpY2tsZRgEIAEoCzIXLmxpdmVraXQuVHJpY2tsZV'
        'JlcXVlc3RIAFIHdHJpY2tsZRI3CglhZGRfdHJhY2sYBSABKAsyGC5saXZla2l0LkFkZFRyYWNr'
        'UmVxdWVzdEgAUghhZGRUcmFjaxIvCgRtdXRlGAYgASgLMhkubGl2ZWtpdC5NdXRlVHJhY2tSZX'
        'F1ZXN0SABSBG11dGUSTQoPdXBkYXRlX21ldGFkYXRhGAcgASgLMiIubGl2ZWtpdC5VcGRhdGVQ'
        'YXJ0aWNpcGFudE1ldGFkYXRhSABSDnVwZGF0ZU1ldGFkYXRhEk4KEnVwZGF0ZV9hdWRpb190cm'
        'FjaxgIIAEoCzIeLmxpdmVraXQuVXBkYXRlTG9jYWxBdWRpb1RyYWNrSABSEHVwZGF0ZUF1ZGlv'
        'VHJhY2sSTgoSdXBkYXRlX3ZpZGVvX3RyYWNrGAkgASgLMh4ubGl2ZWtpdC5VcGRhdGVMb2NhbF'
        'ZpZGVvVHJhY2tIAFIQdXBkYXRlVmlkZW9UcmFjaxJQChJwdWJsaXNoX2RhdGFfdHJhY2sYCiAB'
        'KAsyIC5saXZla2l0LlB1Ymxpc2hEYXRhVHJhY2tSZXF1ZXN0SABSEHB1Ymxpc2hEYXRhVHJhY2'
        'sSVgoUdW5wdWJsaXNoX2RhdGFfdHJhY2sYCyABKAsyIi5saXZla2l0LlVucHVibGlzaERhdGFU'
        'cmFja1JlcXVlc3RIAFISdW5wdWJsaXNoRGF0YVRyYWNrIs4BCgZSZWFzb24SBgoCT0sQABINCg'
        'lOT1RfRk9VTkQQARIPCgtOT1RfQUxMT1dFRBACEhIKDkxJTUlUX0VYQ0VFREVEEAMSCgoGUVVF'
        'VUVEEAQSFAoQVU5TVVBQT1JURURfVFlQRRAFEhYKElVOQ0xBU1NJRklFRF9FUlJPUhAGEhIKDk'
        'lOVkFMSURfSEFORExFEAcSEAoMSU5WQUxJRF9OQU1FEAgSFAoQRFVQTElDQVRFX0hBTkRMRRAJ'
        'EhIKDkRVUExJQ0FURV9OQU1FEApCCQoHcmVxdWVzdA==');

@$core.Deprecated('Use trackSubscribedDescriptor instead')
const TrackSubscribed$json = {
  '1': 'TrackSubscribed',
  '2': [
    {'1': 'track_sid', '3': 1, '4': 1, '5': 9, '10': 'trackSid'},
  ],
};

/// Descriptor for `TrackSubscribed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackSubscribedDescriptor =
    $convert.base64Decode('Cg9UcmFja1N1YnNjcmliZWQSGwoJdHJhY2tfc2lkGAEgASgJUgh0cmFja1NpZA==');

@$core.Deprecated('Use connectionSettingsDescriptor instead')
const ConnectionSettings$json = {
  '1': 'ConnectionSettings',
  '2': [
    {'1': 'auto_subscribe', '3': 1, '4': 1, '5': 8, '10': 'autoSubscribe'},
    {'1': 'adaptive_stream', '3': 2, '4': 1, '5': 8, '10': 'adaptiveStream'},
    {'1': 'subscriber_allow_pause', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'subscriberAllowPause', '17': true},
    {'1': 'disable_ice_lite', '3': 4, '4': 1, '5': 8, '10': 'disableIceLite'},
    {'1': 'auto_subscribe_data_track', '3': 5, '4': 1, '5': 8, '9': 1, '10': 'autoSubscribeDataTrack', '17': true},
  ],
  '8': [
    {'1': '_subscriber_allow_pause'},
    {'1': '_auto_subscribe_data_track'},
  ],
};

/// Descriptor for `ConnectionSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionSettingsDescriptor =
    $convert.base64Decode('ChJDb25uZWN0aW9uU2V0dGluZ3MSJQoOYXV0b19zdWJzY3JpYmUYASABKAhSDWF1dG9TdWJzY3'
        'JpYmUSJwoPYWRhcHRpdmVfc3RyZWFtGAIgASgIUg5hZGFwdGl2ZVN0cmVhbRI5ChZzdWJzY3Jp'
        'YmVyX2FsbG93X3BhdXNlGAMgASgISABSFHN1YnNjcmliZXJBbGxvd1BhdXNliAEBEigKEGRpc2'
        'FibGVfaWNlX2xpdGUYBCABKAhSDmRpc2FibGVJY2VMaXRlEj4KGWF1dG9fc3Vic2NyaWJlX2Rh'
        'dGFfdHJhY2sYBSABKAhIAVIWYXV0b1N1YnNjcmliZURhdGFUcmFja4gBAUIZChdfc3Vic2NyaW'
        'Jlcl9hbGxvd19wYXVzZUIcChpfYXV0b19zdWJzY3JpYmVfZGF0YV90cmFjaw==');

@$core.Deprecated('Use joinRequestDescriptor instead')
const JoinRequest$json = {
  '1': 'JoinRequest',
  '2': [
    {'1': 'client_info', '3': 1, '4': 1, '5': 11, '6': '.livekit.ClientInfo', '10': 'clientInfo'},
    {
      '1': 'connection_settings',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.livekit.ConnectionSettings',
      '10': 'connectionSettings'
    },
    {'1': 'metadata', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'metadata'},
    {
      '1': 'participant_attributes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.livekit.JoinRequest.ParticipantAttributesEntry',
      '8': {},
      '10': 'participantAttributes'
    },
    {'1': 'add_track_requests', '3': 5, '4': 3, '5': 11, '6': '.livekit.AddTrackRequest', '10': 'addTrackRequests'},
    {'1': 'publisher_offer', '3': 6, '4': 1, '5': 11, '6': '.livekit.SessionDescription', '10': 'publisherOffer'},
    {'1': 'reconnect', '3': 7, '4': 1, '5': 8, '10': 'reconnect'},
    {'1': 'reconnect_reason', '3': 8, '4': 1, '5': 14, '6': '.livekit.ReconnectReason', '10': 'reconnectReason'},
    {'1': 'participant_sid', '3': 9, '4': 1, '5': 9, '10': 'participantSid'},
    {'1': 'sync_state', '3': 10, '4': 1, '5': 11, '6': '.livekit.SyncState', '10': 'syncState'},
  ],
  '3': [JoinRequest_ParticipantAttributesEntry$json],
};

@$core.Deprecated('Use joinRequestDescriptor instead')
const JoinRequest_ParticipantAttributesEntry$json = {
  '1': 'ParticipantAttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `JoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinRequestDescriptor =
    $convert.base64Decode('CgtKb2luUmVxdWVzdBI0CgtjbGllbnRfaW5mbxgBIAEoCzITLmxpdmVraXQuQ2xpZW50SW5mb1'
        'IKY2xpZW50SW5mbxJMChNjb25uZWN0aW9uX3NldHRpbmdzGAIgASgLMhsubGl2ZWtpdC5Db25u'
        'ZWN0aW9uU2V0dGluZ3NSEmNvbm5lY3Rpb25TZXR0aW5ncxJCCghtZXRhZGF0YRgDIAEoCUImiO'
        'wsAZLsLB48cmVkYWN0ZWQgKHt7IC5TaXplIH19IGJ5dGVzKT5SCG1ldGFkYXRhEo4BChZwYXJ0'
        'aWNpcGFudF9hdHRyaWJ1dGVzGAQgAygLMi8ubGl2ZWtpdC5Kb2luUmVxdWVzdC5QYXJ0aWNpcG'
        'FudEF0dHJpYnV0ZXNFbnRyeUImiOwsAZLsLB48cmVkYWN0ZWQgKHt7IC5TaXplIH19IGJ5dGVz'
        'KT5SFXBhcnRpY2lwYW50QXR0cmlidXRlcxJGChJhZGRfdHJhY2tfcmVxdWVzdHMYBSADKAsyGC'
        '5saXZla2l0LkFkZFRyYWNrUmVxdWVzdFIQYWRkVHJhY2tSZXF1ZXN0cxJECg9wdWJsaXNoZXJf'
        'b2ZmZXIYBiABKAsyGy5saXZla2l0LlNlc3Npb25EZXNjcmlwdGlvblIOcHVibGlzaGVyT2ZmZX'
        'ISHAoJcmVjb25uZWN0GAcgASgIUglyZWNvbm5lY3QSQwoQcmVjb25uZWN0X3JlYXNvbhgIIAEo'
        'DjIYLmxpdmVraXQuUmVjb25uZWN0UmVhc29uUg9yZWNvbm5lY3RSZWFzb24SJwoPcGFydGljaX'
        'BhbnRfc2lkGAkgASgJUg5wYXJ0aWNpcGFudFNpZBIxCgpzeW5jX3N0YXRlGAogASgLMhIubGl2'
        'ZWtpdC5TeW5jU3RhdGVSCXN5bmNTdGF0ZRpIChpQYXJ0aWNpcGFudEF0dHJpYnV0ZXNFbnRyeR'
        'IQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use wrappedJoinRequestDescriptor instead')
const WrappedJoinRequest$json = {
  '1': 'WrappedJoinRequest',
  '2': [
    {'1': 'compression', '3': 1, '4': 1, '5': 14, '6': '.livekit.WrappedJoinRequest.Compression', '10': 'compression'},
    {'1': 'join_request', '3': 2, '4': 1, '5': 12, '10': 'joinRequest'},
  ],
  '4': [WrappedJoinRequest_Compression$json],
};

@$core.Deprecated('Use wrappedJoinRequestDescriptor instead')
const WrappedJoinRequest_Compression$json = {
  '1': 'Compression',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'GZIP', '2': 1},
  ],
};

/// Descriptor for `WrappedJoinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wrappedJoinRequestDescriptor =
    $convert.base64Decode('ChJXcmFwcGVkSm9pblJlcXVlc3QSSQoLY29tcHJlc3Npb24YASABKA4yJy5saXZla2l0LldyYX'
        'BwZWRKb2luUmVxdWVzdC5Db21wcmVzc2lvblILY29tcHJlc3Npb24SIQoMam9pbl9yZXF1ZXN0'
        'GAIgASgMUgtqb2luUmVxdWVzdCIhCgtDb21wcmVzc2lvbhIICgROT05FEAASCAoER1pJUBAB');

@$core.Deprecated('Use mediaSectionsRequirementDescriptor instead')
const MediaSectionsRequirement$json = {
  '1': 'MediaSectionsRequirement',
  '2': [
    {'1': 'num_audios', '3': 1, '4': 1, '5': 13, '10': 'numAudios'},
    {'1': 'num_videos', '3': 2, '4': 1, '5': 13, '10': 'numVideos'},
  ],
};

/// Descriptor for `MediaSectionsRequirement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaSectionsRequirementDescriptor =
    $convert.base64Decode('ChhNZWRpYVNlY3Rpb25zUmVxdWlyZW1lbnQSHQoKbnVtX2F1ZGlvcxgBIAEoDVIJbnVtQXVkaW'
        '9zEh0KCm51bV92aWRlb3MYAiABKA1SCW51bVZpZGVvcw==');
