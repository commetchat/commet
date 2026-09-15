// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'e2ee/options.dart';
import 'events.dart';
import 'managers/event.dart';
import 'options.dart';
import 'proto/livekit_models.pb.dart' as lk_models;
import 'proto/livekit_rtc.pb.dart' as lk_rtc;
import 'types/other.dart';

extension DataPacketKindExt on lk_models.DataPacket_Kind {
  Reliability toSDKType() => {
        lk_models.DataPacket_Kind.RELIABLE: Reliability.reliable,
        lk_models.DataPacket_Kind.LOSSY: Reliability.lossy,
      }[this]!;
}

extension LiveKitEventExt on Iterable<EventsEmitter<LiveKitEvent>> {
  void emit(LiveKitEvent event) => forEach((emitter) => emitter.emit(event));
}

extension ICEServerExt on lk_rtc.ICEServer {
  RTCIceServer toSDKType() => RTCIceServer(
        urls: urls,
        username: username.isNotEmpty ? username : null,
        credential: credential.isNotEmpty ? credential : null,
      );
}

extension IterableExt<E> on Iterable<E> {
  E? elementAtOrNull(int index) => (index >= 0 && index < length) ? elementAt(index) : null;
}

extension ObjectExt on Object {
  String get objectId => '${runtimeType}#${hashCode}';
}

extension ProtocolVersionExt on ProtocolVersion {
  String toStringValue() => {
        ProtocolVersion.v2: '2',
        ProtocolVersion.v3: '3',
        ProtocolVersion.v4: '4',
        ProtocolVersion.v5: '5',
        ProtocolVersion.v6: '6',
        ProtocolVersion.v7: '7',
        ProtocolVersion.v8: '8',
        ProtocolVersion.v9: '9',
        ProtocolVersion.v10: '10',
        ProtocolVersion.v11: '11',
        ProtocolVersion.v12: '12',
        ProtocolVersion.v13: '13',
        ProtocolVersion.v14: '14',
        ProtocolVersion.v15: '15',
        ProtocolVersion.v16: '16',
      }[this]!;
}

extension ReliabilityExt on Reliability {
  lk_models.DataPacket_Kind toPBType() => {
        Reliability.reliable: lk_models.DataPacket_Kind.RELIABLE,
        Reliability.lossy: lk_models.DataPacket_Kind.LOSSY,
      }[this]!;
}

extension RTCDataChannelExt on rtc.RTCDataChannel {
  lk_rtc.DataChannelInfo toLKInfoType() => lk_rtc.DataChannelInfo(
        id: id,
        label: label,
      );
}

extension RTCIceCandidateExt on rtc.RTCIceCandidate {
  static rtc.RTCIceCandidate fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return rtc.RTCIceCandidate(
      map['candidate'] as String?,
      map['sdpMid'] as String?,
      map['sdpMLineIndex'] as int?,
    );
  }

  String toJson() => json.encode(toMap());
}

extension RTCPeerConnectionStateExt on rtc.RTCPeerConnectionState {
  bool isConnected() => this == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  bool isDisconnected() => [
        rtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed,
        rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected,
      ].contains(this);

  bool isFailed() => this == rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed;
}

extension RTCIceTransportPolicyExt on RTCIceTransportPolicy {
  String toStringValue() => {
        RTCIceTransportPolicy.all: 'all',
        RTCIceTransportPolicy.relay: 'relay',
      }[this]!;
}

// not so neat to directly expose protobuf types so we
// define our own types (and convert methods)
extension RTCSessionDescriptionExt on rtc.RTCSessionDescription {
  lk_rtc.SessionDescription toPBType() {
    return lk_rtc.SessionDescription(type: type, sdp: sdp);
  }
}

extension SessionDescriptionExt on lk_rtc.SessionDescription {
  rtc.RTCSessionDescription toSDKType() {
    return rtc.RTCSessionDescription(sdp, type);
  }
}

extension ConnectionQualityExt on lk_models.ConnectionQuality {
  ConnectionQuality toLKType() =>
      {
        lk_models.ConnectionQuality.LOST: ConnectionQuality.lost,
        lk_models.ConnectionQuality.POOR: ConnectionQuality.poor,
        lk_models.ConnectionQuality.GOOD: ConnectionQuality.good,
        lk_models.ConnectionQuality.EXCELLENT: ConnectionQuality.excellent,
      }[this] ??
      ConnectionQuality.unknown;
}

extension VideoQualityExt on lk_models.VideoQuality {
  VideoQuality toLKType() =>
      {
        lk_models.VideoQuality.HIGH: VideoQuality.HIGH,
        lk_models.VideoQuality.MEDIUM: VideoQuality.MEDIUM,
        lk_models.VideoQuality.LOW: VideoQuality.LOW,
      }[this] ??
      VideoQuality.LOW;

  String toRid() => {
        lk_models.VideoQuality.HIGH: 'f',
        lk_models.VideoQuality.MEDIUM: 'h',
        lk_models.VideoQuality.LOW: 'q',
      }[this]!;
}

extension PBVideoQualityExt on VideoQuality {
  lk_models.VideoQuality toPBType() => {
        VideoQuality.HIGH: lk_models.VideoQuality.HIGH,
        VideoQuality.MEDIUM: lk_models.VideoQuality.MEDIUM,
        VideoQuality.LOW: lk_models.VideoQuality.LOW,
      }[this]!;
}

extension TrackTypeExt on lk_models.TrackType {
  TrackType toLKType() =>
      {
        lk_models.TrackType.AUDIO: TrackType.AUDIO,
        lk_models.TrackType.VIDEO: TrackType.VIDEO,
        lk_models.TrackType.DATA: TrackType.DATA,
      }[this] ??
      TrackType.AUDIO;
}

extension PBTrackTypeExt on TrackType {
  lk_models.TrackType toPBType() => {
        TrackType.AUDIO: lk_models.TrackType.AUDIO,
        TrackType.VIDEO: lk_models.TrackType.VIDEO,
        TrackType.DATA: lk_models.TrackType.DATA,
      }[this]!;
}

extension PBTrackSourceExt on lk_models.TrackSource {
  TrackSource toLKType() =>
      <lk_models.TrackSource, TrackSource>{
        lk_models.TrackSource.CAMERA: TrackSource.camera,
        lk_models.TrackSource.MICROPHONE: TrackSource.microphone,
        lk_models.TrackSource.SCREEN_SHARE: TrackSource.screenShareVideo,
        lk_models.TrackSource.SCREEN_SHARE_AUDIO: TrackSource.screenShareAudio,
      }[this] ??
      TrackSource.unknown;
}

extension LKTrackSourceExt on TrackSource {
  lk_models.TrackSource toPBType() =>
      <TrackSource, lk_models.TrackSource>{
        TrackSource.camera: lk_models.TrackSource.CAMERA,
        TrackSource.microphone: lk_models.TrackSource.MICROPHONE,
        TrackSource.screenShareVideo: lk_models.TrackSource.SCREEN_SHARE,
        TrackSource.screenShareAudio: lk_models.TrackSource.SCREEN_SHARE_AUDIO,
      }[this] ??
      lk_models.TrackSource.UNKNOWN;
}

extension PBStreamStateExt on lk_rtc.StreamState {
  StreamState toLKType() =>
      <lk_rtc.StreamState, StreamState>{
        lk_rtc.StreamState.ACTIVE: StreamState.active,
      }[this] ??
      StreamState.paused;
}

extension ParticipantTrackPermissionExt on ParticipantTrackPermission {
  lk_rtc.TrackPermission toPBType() => lk_rtc.TrackPermission(
        participantIdentity: participantIdentity,
        allTracks: allTracksAllowed,
        trackSids: allowedTrackSids,
      );
}

extension WidgetsBindingCompatible on WidgetsBinding {
  // always return optional type for compatibility with flutter v2 and v3
  static WidgetsBinding? get instance => WidgetsBinding.instance;
}

extension EncryptionTypeExt on lk_models.Encryption_Type {
  EncryptionType toLkType() => {
        lk_models.Encryption_Type.NONE: EncryptionType.kNone,
        lk_models.Encryption_Type.GCM: EncryptionType.kGcm,
        lk_models.Encryption_Type.CUSTOM: EncryptionType.kCustom,
      }[this]!;
}

extension DisconnectReasonExt on lk_models.DisconnectReason {
  DisconnectReason toSDKType() => {
        lk_models.DisconnectReason.UNKNOWN_REASON: DisconnectReason.unknown,
        lk_models.DisconnectReason.CLIENT_INITIATED: DisconnectReason.clientInitiated,
        lk_models.DisconnectReason.DUPLICATE_IDENTITY: DisconnectReason.duplicateIdentity,
        lk_models.DisconnectReason.SERVER_SHUTDOWN: DisconnectReason.serverShutdown,
        lk_models.DisconnectReason.PARTICIPANT_REMOVED: DisconnectReason.participantRemoved,
        lk_models.DisconnectReason.ROOM_DELETED: DisconnectReason.roomDeleted,
        lk_models.DisconnectReason.STATE_MISMATCH: DisconnectReason.stateMismatch,
        lk_models.DisconnectReason.JOIN_FAILURE: DisconnectReason.joinFailure,
      }[this]!;
}

extension ParticipantTypeExt on lk_models.ParticipantInfo_Kind {
  ParticipantKind toLKType() => {
        lk_models.ParticipantInfo_Kind.STANDARD: ParticipantKind.STANDARD,
        lk_models.ParticipantInfo_Kind.INGRESS: ParticipantKind.INGRESS,
        lk_models.ParticipantInfo_Kind.EGRESS: ParticipantKind.EGRESS,
        lk_models.ParticipantInfo_Kind.SIP: ParticipantKind.SIP,
        lk_models.ParticipantInfo_Kind.AGENT: ParticipantKind.AGENT,
      }[this]!;
}

extension DegradationPreferenceExt on DegradationPreference {
  rtc.RTCDegradationPreference toRTCType() => {
        DegradationPreference.maintainFramerate: rtc.RTCDegradationPreference.MAINTAIN_FRAMERATE,
        DegradationPreference.maintainResolution: rtc.RTCDegradationPreference.MAINTAIN_RESOLUTION,
        DegradationPreference.balanced: rtc.RTCDegradationPreference.BALANCED,
        DegradationPreference.maintainFramerateAndResolution:
            rtc.RTCDegradationPreference.MAINTAIN_FRAMERATE_AND_RESOLUTION,
      }[this]!;
}

extension RoomOptionsEx on RoomOptions {
  lk_models.Encryption_Type get lkEncryptionType {
    // ignore: deprecated_member_use_from_same_package
    final e2ee = encryption ?? e2eeOptions;
    return (e2ee != null)
        ? {
            EncryptionType.kNone: lk_models.Encryption_Type.NONE,
            EncryptionType.kGcm: lk_models.Encryption_Type.GCM,
            EncryptionType.kCustom: lk_models.Encryption_Type.CUSTOM,
          }[e2ee.encryptionType]!
        : lk_models.Encryption_Type.NONE;
  }
}
