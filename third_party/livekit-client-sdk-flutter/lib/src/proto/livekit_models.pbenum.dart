// This is a generated file - do not edit.
//
// Generated from livekit_models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AudioCodec extends $pb.ProtobufEnum {
  static const AudioCodec DEFAULT_AC = AudioCodec._(0, _omitEnumNames ? '' : 'DEFAULT_AC');
  static const AudioCodec OPUS = AudioCodec._(1, _omitEnumNames ? '' : 'OPUS');
  static const AudioCodec AAC = AudioCodec._(2, _omitEnumNames ? '' : 'AAC');
  static const AudioCodec AC_MP3 = AudioCodec._(3, _omitEnumNames ? '' : 'AC_MP3');

  static const $core.List<AudioCodec> values = <AudioCodec>[
    DEFAULT_AC,
    OPUS,
    AAC,
    AC_MP3,
  ];

  static final $core.List<AudioCodec?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AudioCodec? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioCodec._(super.value, super.name);
}

class VideoCodec extends $pb.ProtobufEnum {
  static const VideoCodec DEFAULT_VC = VideoCodec._(0, _omitEnumNames ? '' : 'DEFAULT_VC');
  static const VideoCodec H264_BASELINE = VideoCodec._(1, _omitEnumNames ? '' : 'H264_BASELINE');
  static const VideoCodec H264_MAIN = VideoCodec._(2, _omitEnumNames ? '' : 'H264_MAIN');
  static const VideoCodec H264_HIGH = VideoCodec._(3, _omitEnumNames ? '' : 'H264_HIGH');
  static const VideoCodec VP8 = VideoCodec._(4, _omitEnumNames ? '' : 'VP8');

  static const $core.List<VideoCodec> values = <VideoCodec>[
    DEFAULT_VC,
    H264_BASELINE,
    H264_MAIN,
    H264_HIGH,
    VP8,
  ];

  static final $core.List<VideoCodec?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static VideoCodec? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VideoCodec._(super.value, super.name);
}

class ImageCodec extends $pb.ProtobufEnum {
  static const ImageCodec IC_DEFAULT = ImageCodec._(0, _omitEnumNames ? '' : 'IC_DEFAULT');
  static const ImageCodec IC_JPEG = ImageCodec._(1, _omitEnumNames ? '' : 'IC_JPEG');

  static const $core.List<ImageCodec> values = <ImageCodec>[
    IC_DEFAULT,
    IC_JPEG,
  ];

  static final $core.List<ImageCodec?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ImageCodec? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ImageCodec._(super.value, super.name);
}

/// Policy for publisher to handle subscribers that are unable to support the primary codec of a track
class BackupCodecPolicy extends $pb.ProtobufEnum {
  /// default behavior, the track prefer to regress to backup codec and all subscribers will receive the backup codec,
  /// the sfu will try to regress codec if possible but not assured.
  static const BackupCodecPolicy PREFER_REGRESSION = BackupCodecPolicy._(0, _omitEnumNames ? '' : 'PREFER_REGRESSION');

  /// encoding/send the primary and backup codec simultaneously
  static const BackupCodecPolicy SIMULCAST = BackupCodecPolicy._(1, _omitEnumNames ? '' : 'SIMULCAST');

  /// force the track to regress to backup codec, this option can be used in video conference or the publisher has limited bandwidth/encoding power
  static const BackupCodecPolicy REGRESSION = BackupCodecPolicy._(2, _omitEnumNames ? '' : 'REGRESSION');

  static const $core.List<BackupCodecPolicy> values = <BackupCodecPolicy>[
    PREFER_REGRESSION,
    SIMULCAST,
    REGRESSION,
  ];

  static final $core.List<BackupCodecPolicy?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static BackupCodecPolicy? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BackupCodecPolicy._(super.value, super.name);
}

class TrackType extends $pb.ProtobufEnum {
  static const TrackType AUDIO = TrackType._(0, _omitEnumNames ? '' : 'AUDIO');
  static const TrackType VIDEO = TrackType._(1, _omitEnumNames ? '' : 'VIDEO');
  static const TrackType DATA = TrackType._(2, _omitEnumNames ? '' : 'DATA');

  static const $core.List<TrackType> values = <TrackType>[
    AUDIO,
    VIDEO,
    DATA,
  ];

  static final $core.List<TrackType?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static TrackType? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TrackType._(super.value, super.name);
}

class TrackSource extends $pb.ProtobufEnum {
  static const TrackSource UNKNOWN = TrackSource._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const TrackSource CAMERA = TrackSource._(1, _omitEnumNames ? '' : 'CAMERA');
  static const TrackSource MICROPHONE = TrackSource._(2, _omitEnumNames ? '' : 'MICROPHONE');
  static const TrackSource SCREEN_SHARE = TrackSource._(3, _omitEnumNames ? '' : 'SCREEN_SHARE');
  static const TrackSource SCREEN_SHARE_AUDIO = TrackSource._(4, _omitEnumNames ? '' : 'SCREEN_SHARE_AUDIO');

  static const $core.List<TrackSource> values = <TrackSource>[
    UNKNOWN,
    CAMERA,
    MICROPHONE,
    SCREEN_SHARE,
    SCREEN_SHARE_AUDIO,
  ];

  static final $core.List<TrackSource?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static TrackSource? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TrackSource._(super.value, super.name);
}

class DataTrackExtensionID extends $pb.ProtobufEnum {
  static const DataTrackExtensionID DTEI_INVALID = DataTrackExtensionID._(0, _omitEnumNames ? '' : 'DTEI_INVALID');
  static const DataTrackExtensionID DTEI_PARTICIPANT_SID =
      DataTrackExtensionID._(1, _omitEnumNames ? '' : 'DTEI_PARTICIPANT_SID');

  static const $core.List<DataTrackExtensionID> values = <DataTrackExtensionID>[
    DTEI_INVALID,
    DTEI_PARTICIPANT_SID,
  ];

  static final $core.List<DataTrackExtensionID?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static DataTrackExtensionID? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DataTrackExtensionID._(super.value, super.name);
}

class VideoQuality extends $pb.ProtobufEnum {
  static const VideoQuality LOW = VideoQuality._(0, _omitEnumNames ? '' : 'LOW');
  static const VideoQuality MEDIUM = VideoQuality._(1, _omitEnumNames ? '' : 'MEDIUM');
  static const VideoQuality HIGH = VideoQuality._(2, _omitEnumNames ? '' : 'HIGH');
  static const VideoQuality OFF = VideoQuality._(3, _omitEnumNames ? '' : 'OFF');

  static const $core.List<VideoQuality> values = <VideoQuality>[
    LOW,
    MEDIUM,
    HIGH,
    OFF,
  ];

  static final $core.List<VideoQuality?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static VideoQuality? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VideoQuality._(super.value, super.name);
}

class ConnectionQuality extends $pb.ProtobufEnum {
  static const ConnectionQuality POOR = ConnectionQuality._(0, _omitEnumNames ? '' : 'POOR');
  static const ConnectionQuality GOOD = ConnectionQuality._(1, _omitEnumNames ? '' : 'GOOD');
  static const ConnectionQuality EXCELLENT = ConnectionQuality._(2, _omitEnumNames ? '' : 'EXCELLENT');
  static const ConnectionQuality LOST = ConnectionQuality._(3, _omitEnumNames ? '' : 'LOST');

  static const $core.List<ConnectionQuality> values = <ConnectionQuality>[
    POOR,
    GOOD,
    EXCELLENT,
    LOST,
  ];

  static final $core.List<ConnectionQuality?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ConnectionQuality? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConnectionQuality._(super.value, super.name);
}

class ClientConfigSetting extends $pb.ProtobufEnum {
  static const ClientConfigSetting UNSET = ClientConfigSetting._(0, _omitEnumNames ? '' : 'UNSET');
  static const ClientConfigSetting DISABLED = ClientConfigSetting._(1, _omitEnumNames ? '' : 'DISABLED');
  static const ClientConfigSetting ENABLED = ClientConfigSetting._(2, _omitEnumNames ? '' : 'ENABLED');

  static const $core.List<ClientConfigSetting> values = <ClientConfigSetting>[
    UNSET,
    DISABLED,
    ENABLED,
  ];

  static final $core.List<ClientConfigSetting?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ClientConfigSetting? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ClientConfigSetting._(super.value, super.name);
}

class DisconnectReason extends $pb.ProtobufEnum {
  static const DisconnectReason UNKNOWN_REASON = DisconnectReason._(0, _omitEnumNames ? '' : 'UNKNOWN_REASON');

  /// the client initiated the disconnect
  static const DisconnectReason CLIENT_INITIATED = DisconnectReason._(1, _omitEnumNames ? '' : 'CLIENT_INITIATED');

  /// another participant with the same identity has joined the room
  static const DisconnectReason DUPLICATE_IDENTITY = DisconnectReason._(2, _omitEnumNames ? '' : 'DUPLICATE_IDENTITY');

  /// the server instance is shutting down
  static const DisconnectReason SERVER_SHUTDOWN = DisconnectReason._(3, _omitEnumNames ? '' : 'SERVER_SHUTDOWN');

  /// RoomService.RemoveParticipant was called
  static const DisconnectReason PARTICIPANT_REMOVED =
      DisconnectReason._(4, _omitEnumNames ? '' : 'PARTICIPANT_REMOVED');

  /// RoomService.DeleteRoom was called
  static const DisconnectReason ROOM_DELETED = DisconnectReason._(5, _omitEnumNames ? '' : 'ROOM_DELETED');

  /// the client is attempting to resume a session, but server is not aware of it
  static const DisconnectReason STATE_MISMATCH = DisconnectReason._(6, _omitEnumNames ? '' : 'STATE_MISMATCH');

  /// client was unable to connect fully
  static const DisconnectReason JOIN_FAILURE = DisconnectReason._(7, _omitEnumNames ? '' : 'JOIN_FAILURE');

  /// Cloud-only, the server requested Participant to migrate the connection elsewhere
  static const DisconnectReason MIGRATION = DisconnectReason._(8, _omitEnumNames ? '' : 'MIGRATION');

  /// the signal websocket was closed unexpectedly
  static const DisconnectReason SIGNAL_CLOSE = DisconnectReason._(9, _omitEnumNames ? '' : 'SIGNAL_CLOSE');

  /// the room was closed, due to all Standard and Ingress participants having left
  static const DisconnectReason ROOM_CLOSED = DisconnectReason._(10, _omitEnumNames ? '' : 'ROOM_CLOSED');

  /// SIP callee did not respond in time
  static const DisconnectReason USER_UNAVAILABLE = DisconnectReason._(11, _omitEnumNames ? '' : 'USER_UNAVAILABLE');

  /// SIP callee rejected the call (busy)
  static const DisconnectReason USER_REJECTED = DisconnectReason._(12, _omitEnumNames ? '' : 'USER_REJECTED');

  /// SIP protocol failure or unexpected response
  static const DisconnectReason SIP_TRUNK_FAILURE = DisconnectReason._(13, _omitEnumNames ? '' : 'SIP_TRUNK_FAILURE');

  /// server timed out a participant session
  static const DisconnectReason CONNECTION_TIMEOUT = DisconnectReason._(14, _omitEnumNames ? '' : 'CONNECTION_TIMEOUT');

  /// media stream failure or media timeout
  static const DisconnectReason MEDIA_FAILURE = DisconnectReason._(15, _omitEnumNames ? '' : 'MEDIA_FAILURE');

  static const $core.List<DisconnectReason> values = <DisconnectReason>[
    UNKNOWN_REASON,
    CLIENT_INITIATED,
    DUPLICATE_IDENTITY,
    SERVER_SHUTDOWN,
    PARTICIPANT_REMOVED,
    ROOM_DELETED,
    STATE_MISMATCH,
    JOIN_FAILURE,
    MIGRATION,
    SIGNAL_CLOSE,
    ROOM_CLOSED,
    USER_UNAVAILABLE,
    USER_REJECTED,
    SIP_TRUNK_FAILURE,
    CONNECTION_TIMEOUT,
    MEDIA_FAILURE,
  ];

  static final $core.List<DisconnectReason?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 15);
  static DisconnectReason? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DisconnectReason._(super.value, super.name);
}

class ReconnectReason extends $pb.ProtobufEnum {
  static const ReconnectReason RR_UNKNOWN = ReconnectReason._(0, _omitEnumNames ? '' : 'RR_UNKNOWN');
  static const ReconnectReason RR_SIGNAL_DISCONNECTED =
      ReconnectReason._(1, _omitEnumNames ? '' : 'RR_SIGNAL_DISCONNECTED');
  static const ReconnectReason RR_PUBLISHER_FAILED = ReconnectReason._(2, _omitEnumNames ? '' : 'RR_PUBLISHER_FAILED');
  static const ReconnectReason RR_SUBSCRIBER_FAILED =
      ReconnectReason._(3, _omitEnumNames ? '' : 'RR_SUBSCRIBER_FAILED');
  static const ReconnectReason RR_SWITCH_CANDIDATE = ReconnectReason._(4, _omitEnumNames ? '' : 'RR_SWITCH_CANDIDATE');

  static const $core.List<ReconnectReason> values = <ReconnectReason>[
    RR_UNKNOWN,
    RR_SIGNAL_DISCONNECTED,
    RR_PUBLISHER_FAILED,
    RR_SUBSCRIBER_FAILED,
    RR_SWITCH_CANDIDATE,
  ];

  static final $core.List<ReconnectReason?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ReconnectReason? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReconnectReason._(super.value, super.name);
}

class SubscriptionError extends $pb.ProtobufEnum {
  static const SubscriptionError SE_UNKNOWN = SubscriptionError._(0, _omitEnumNames ? '' : 'SE_UNKNOWN');
  static const SubscriptionError SE_CODEC_UNSUPPORTED =
      SubscriptionError._(1, _omitEnumNames ? '' : 'SE_CODEC_UNSUPPORTED');
  static const SubscriptionError SE_TRACK_NOTFOUND = SubscriptionError._(2, _omitEnumNames ? '' : 'SE_TRACK_NOTFOUND');

  static const $core.List<SubscriptionError> values = <SubscriptionError>[
    SE_UNKNOWN,
    SE_CODEC_UNSUPPORTED,
    SE_TRACK_NOTFOUND,
  ];

  static final $core.List<SubscriptionError?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SubscriptionError? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SubscriptionError._(super.value, super.name);
}

class AudioTrackFeature extends $pb.ProtobufEnum {
  static const AudioTrackFeature TF_STEREO = AudioTrackFeature._(0, _omitEnumNames ? '' : 'TF_STEREO');
  static const AudioTrackFeature TF_NO_DTX = AudioTrackFeature._(1, _omitEnumNames ? '' : 'TF_NO_DTX');
  static const AudioTrackFeature TF_AUTO_GAIN_CONTROL =
      AudioTrackFeature._(2, _omitEnumNames ? '' : 'TF_AUTO_GAIN_CONTROL');
  static const AudioTrackFeature TF_ECHO_CANCELLATION =
      AudioTrackFeature._(3, _omitEnumNames ? '' : 'TF_ECHO_CANCELLATION');
  static const AudioTrackFeature TF_NOISE_SUPPRESSION =
      AudioTrackFeature._(4, _omitEnumNames ? '' : 'TF_NOISE_SUPPRESSION');
  static const AudioTrackFeature TF_ENHANCED_NOISE_CANCELLATION =
      AudioTrackFeature._(5, _omitEnumNames ? '' : 'TF_ENHANCED_NOISE_CANCELLATION');
  static const AudioTrackFeature TF_PRECONNECT_BUFFER =
      AudioTrackFeature._(6, _omitEnumNames ? '' : 'TF_PRECONNECT_BUFFER');

  static const $core.List<AudioTrackFeature> values = <AudioTrackFeature>[
    TF_STEREO,
    TF_NO_DTX,
    TF_AUTO_GAIN_CONTROL,
    TF_ECHO_CANCELLATION,
    TF_NOISE_SUPPRESSION,
    TF_ENHANCED_NOISE_CANCELLATION,
    TF_PRECONNECT_BUFFER,
  ];

  static final $core.List<AudioTrackFeature?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 6);
  static AudioTrackFeature? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioTrackFeature._(super.value, super.name);
}

class ParticipantInfo_State extends $pb.ProtobufEnum {
  /// websocket' connected, but not offered yet
  static const ParticipantInfo_State JOINING = ParticipantInfo_State._(0, _omitEnumNames ? '' : 'JOINING');

  /// server received client offer
  static const ParticipantInfo_State JOINED = ParticipantInfo_State._(1, _omitEnumNames ? '' : 'JOINED');

  /// ICE connectivity established
  static const ParticipantInfo_State ACTIVE = ParticipantInfo_State._(2, _omitEnumNames ? '' : 'ACTIVE');

  /// WS disconnected
  static const ParticipantInfo_State DISCONNECTED = ParticipantInfo_State._(3, _omitEnumNames ? '' : 'DISCONNECTED');

  static const $core.List<ParticipantInfo_State> values = <ParticipantInfo_State>[
    JOINING,
    JOINED,
    ACTIVE,
    DISCONNECTED,
  ];

  static final $core.List<ParticipantInfo_State?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ParticipantInfo_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ParticipantInfo_State._(super.value, super.name);
}

class ParticipantInfo_Kind extends $pb.ProtobufEnum {
  /// standard participants, e.g. web clients
  static const ParticipantInfo_Kind STANDARD = ParticipantInfo_Kind._(0, _omitEnumNames ? '' : 'STANDARD');

  /// only ingests streams
  static const ParticipantInfo_Kind INGRESS = ParticipantInfo_Kind._(1, _omitEnumNames ? '' : 'INGRESS');

  /// only consumes streams
  static const ParticipantInfo_Kind EGRESS = ParticipantInfo_Kind._(2, _omitEnumNames ? '' : 'EGRESS');

  /// SIP participants
  static const ParticipantInfo_Kind SIP = ParticipantInfo_Kind._(3, _omitEnumNames ? '' : 'SIP');

  /// LiveKit agents
  static const ParticipantInfo_Kind AGENT = ParticipantInfo_Kind._(4, _omitEnumNames ? '' : 'AGENT');

  /// Connectors participants
  static const ParticipantInfo_Kind CONNECTOR = ParticipantInfo_Kind._(7, _omitEnumNames ? '' : 'CONNECTOR');

  /// Bridge participants
  static const ParticipantInfo_Kind BRIDGE = ParticipantInfo_Kind._(8, _omitEnumNames ? '' : 'BRIDGE');

  static const $core.List<ParticipantInfo_Kind> values = <ParticipantInfo_Kind>[
    STANDARD,
    INGRESS,
    EGRESS,
    SIP,
    AGENT,
    CONNECTOR,
    BRIDGE,
  ];

  static final $core.List<ParticipantInfo_Kind?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 8);
  static ParticipantInfo_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ParticipantInfo_Kind._(super.value, super.name);
}

class ParticipantInfo_KindDetail extends $pb.ProtobufEnum {
  static const ParticipantInfo_KindDetail CLOUD_AGENT =
      ParticipantInfo_KindDetail._(0, _omitEnumNames ? '' : 'CLOUD_AGENT');
  static const ParticipantInfo_KindDetail FORWARDED =
      ParticipantInfo_KindDetail._(1, _omitEnumNames ? '' : 'FORWARDED');
  static const ParticipantInfo_KindDetail CONNECTOR_WHATSAPP =
      ParticipantInfo_KindDetail._(2, _omitEnumNames ? '' : 'CONNECTOR_WHATSAPP');
  static const ParticipantInfo_KindDetail CONNECTOR_TWILIO =
      ParticipantInfo_KindDetail._(3, _omitEnumNames ? '' : 'CONNECTOR_TWILIO');
  static const ParticipantInfo_KindDetail BRIDGE_RTSP =
      ParticipantInfo_KindDetail._(4, _omitEnumNames ? '' : 'BRIDGE_RTSP');

  static const $core.List<ParticipantInfo_KindDetail> values = <ParticipantInfo_KindDetail>[
    CLOUD_AGENT,
    FORWARDED,
    CONNECTOR_WHATSAPP,
    CONNECTOR_TWILIO,
    BRIDGE_RTSP,
  ];

  static final $core.List<ParticipantInfo_KindDetail?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ParticipantInfo_KindDetail? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ParticipantInfo_KindDetail._(super.value, super.name);
}

class Encryption_Type extends $pb.ProtobufEnum {
  static const Encryption_Type NONE = Encryption_Type._(0, _omitEnumNames ? '' : 'NONE');
  static const Encryption_Type GCM = Encryption_Type._(1, _omitEnumNames ? '' : 'GCM');
  static const Encryption_Type CUSTOM = Encryption_Type._(2, _omitEnumNames ? '' : 'CUSTOM');

  static const $core.List<Encryption_Type> values = <Encryption_Type>[
    NONE,
    GCM,
    CUSTOM,
  ];

  static final $core.List<Encryption_Type?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Encryption_Type? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Encryption_Type._(super.value, super.name);
}

class VideoLayer_Mode extends $pb.ProtobufEnum {
  static const VideoLayer_Mode MODE_UNUSED = VideoLayer_Mode._(0, _omitEnumNames ? '' : 'MODE_UNUSED');
  static const VideoLayer_Mode ONE_SPATIAL_LAYER_PER_STREAM =
      VideoLayer_Mode._(1, _omitEnumNames ? '' : 'ONE_SPATIAL_LAYER_PER_STREAM');
  static const VideoLayer_Mode MULTIPLE_SPATIAL_LAYERS_PER_STREAM =
      VideoLayer_Mode._(2, _omitEnumNames ? '' : 'MULTIPLE_SPATIAL_LAYERS_PER_STREAM');
  static const VideoLayer_Mode ONE_SPATIAL_LAYER_PER_STREAM_INCOMPLETE_RTCP_SR =
      VideoLayer_Mode._(3, _omitEnumNames ? '' : 'ONE_SPATIAL_LAYER_PER_STREAM_INCOMPLETE_RTCP_SR');

  static const $core.List<VideoLayer_Mode> values = <VideoLayer_Mode>[
    MODE_UNUSED,
    ONE_SPATIAL_LAYER_PER_STREAM,
    MULTIPLE_SPATIAL_LAYERS_PER_STREAM,
    ONE_SPATIAL_LAYER_PER_STREAM_INCOMPLETE_RTCP_SR,
  ];

  static final $core.List<VideoLayer_Mode?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static VideoLayer_Mode? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VideoLayer_Mode._(super.value, super.name);
}

class DataPacket_Kind extends $pb.ProtobufEnum {
  static const DataPacket_Kind RELIABLE = DataPacket_Kind._(0, _omitEnumNames ? '' : 'RELIABLE');
  static const DataPacket_Kind LOSSY = DataPacket_Kind._(1, _omitEnumNames ? '' : 'LOSSY');

  static const $core.List<DataPacket_Kind> values = <DataPacket_Kind>[
    RELIABLE,
    LOSSY,
  ];

  static final $core.List<DataPacket_Kind?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static DataPacket_Kind? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DataPacket_Kind._(super.value, super.name);
}

class ServerInfo_Edition extends $pb.ProtobufEnum {
  static const ServerInfo_Edition Standard = ServerInfo_Edition._(0, _omitEnumNames ? '' : 'Standard');
  static const ServerInfo_Edition Cloud = ServerInfo_Edition._(1, _omitEnumNames ? '' : 'Cloud');

  static const $core.List<ServerInfo_Edition> values = <ServerInfo_Edition>[
    Standard,
    Cloud,
  ];

  static final $core.List<ServerInfo_Edition?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ServerInfo_Edition? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ServerInfo_Edition._(super.value, super.name);
}

class ClientInfo_SDK extends $pb.ProtobufEnum {
  static const ClientInfo_SDK UNKNOWN = ClientInfo_SDK._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const ClientInfo_SDK JS = ClientInfo_SDK._(1, _omitEnumNames ? '' : 'JS');
  static const ClientInfo_SDK SWIFT = ClientInfo_SDK._(2, _omitEnumNames ? '' : 'SWIFT');
  static const ClientInfo_SDK ANDROID = ClientInfo_SDK._(3, _omitEnumNames ? '' : 'ANDROID');
  static const ClientInfo_SDK FLUTTER = ClientInfo_SDK._(4, _omitEnumNames ? '' : 'FLUTTER');
  static const ClientInfo_SDK GO = ClientInfo_SDK._(5, _omitEnumNames ? '' : 'GO');
  static const ClientInfo_SDK UNITY = ClientInfo_SDK._(6, _omitEnumNames ? '' : 'UNITY');
  static const ClientInfo_SDK REACT_NATIVE = ClientInfo_SDK._(7, _omitEnumNames ? '' : 'REACT_NATIVE');
  static const ClientInfo_SDK RUST = ClientInfo_SDK._(8, _omitEnumNames ? '' : 'RUST');
  static const ClientInfo_SDK PYTHON = ClientInfo_SDK._(9, _omitEnumNames ? '' : 'PYTHON');
  static const ClientInfo_SDK CPP = ClientInfo_SDK._(10, _omitEnumNames ? '' : 'CPP');
  static const ClientInfo_SDK UNITY_WEB = ClientInfo_SDK._(11, _omitEnumNames ? '' : 'UNITY_WEB');
  static const ClientInfo_SDK NODE = ClientInfo_SDK._(12, _omitEnumNames ? '' : 'NODE');
  static const ClientInfo_SDK UNREAL = ClientInfo_SDK._(13, _omitEnumNames ? '' : 'UNREAL');
  static const ClientInfo_SDK ESP32 = ClientInfo_SDK._(14, _omitEnumNames ? '' : 'ESP32');

  static const $core.List<ClientInfo_SDK> values = <ClientInfo_SDK>[
    UNKNOWN,
    JS,
    SWIFT,
    ANDROID,
    FLUTTER,
    GO,
    UNITY,
    REACT_NATIVE,
    RUST,
    PYTHON,
    CPP,
    UNITY_WEB,
    NODE,
    UNREAL,
    ESP32,
  ];

  static final $core.List<ClientInfo_SDK?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 14);
  static ClientInfo_SDK? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ClientInfo_SDK._(super.value, super.name);
}

/// enum for operation types (specific to TextHeader)
class DataStream_OperationType extends $pb.ProtobufEnum {
  static const DataStream_OperationType CREATE = DataStream_OperationType._(0, _omitEnumNames ? '' : 'CREATE');
  static const DataStream_OperationType UPDATE = DataStream_OperationType._(1, _omitEnumNames ? '' : 'UPDATE');
  static const DataStream_OperationType DELETE = DataStream_OperationType._(2, _omitEnumNames ? '' : 'DELETE');
  static const DataStream_OperationType REACTION = DataStream_OperationType._(3, _omitEnumNames ? '' : 'REACTION');

  static const $core.List<DataStream_OperationType> values = <DataStream_OperationType>[
    CREATE,
    UPDATE,
    DELETE,
    REACTION,
  ];

  static final $core.List<DataStream_OperationType?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static DataStream_OperationType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DataStream_OperationType._(super.value, super.name);
}

const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
