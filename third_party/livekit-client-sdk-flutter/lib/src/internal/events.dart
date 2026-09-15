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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../e2ee/options.dart';
import '../events.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import '../track/options.dart';
import '../track/track.dart';
import '../types/other.dart';

@internal
abstract class EnginePeerStateUpdatedEvent with EngineEvent, InternalEvent {
  final rtc.RTCPeerConnectionState state;
  final bool isPrimary;
  const EnginePeerStateUpdatedEvent({
    required this.state,
    required this.isPrimary,
  });

  @override
  String toString() => '${runtimeType}(state: ${state}, isPrimary: ${isPrimary})';
}

@internal
class EngineSubscriberPeerStateUpdatedEvent extends EnginePeerStateUpdatedEvent {
  const EngineSubscriberPeerStateUpdatedEvent({
    required rtc.RTCPeerConnectionState state,
    required bool isPrimary,
  }) : super(
          state: state,
          isPrimary: isPrimary,
        );

  @override
  String toString() => '${runtimeType}(state: ${state}, isPrimary: ${isPrimary})';
}

@internal
class EnginePublisherPeerStateUpdatedEvent extends EnginePeerStateUpdatedEvent {
  const EnginePublisherPeerStateUpdatedEvent({
    required rtc.RTCPeerConnectionState state,
    required bool isPrimary,
  }) : super(
          state: state,
          isPrimary: isPrimary,
        );
  @override
  String toString() => '${runtimeType}(state: ${state}, isPrimary: ${isPrimary})';
}

@internal
class TrackStreamUpdatedEvent with TrackEvent, InternalEvent {
  final Track track;
  final rtc.MediaStream stream;
  const TrackStreamUpdatedEvent({
    required this.track,
    required this.stream,
  });

  @override
  String toString() => '${runtimeType}(track: ${track}, stream: ${stream})';
}

@internal
class AudioPlaybackStarted with TrackEvent, EngineEvent, InternalEvent {
  final Track track;
  const AudioPlaybackStarted({
    required this.track,
  });

  @override
  String toString() => '${runtimeType}(track: ${track})';
}

@internal
class AudioPlaybackFailed with TrackEvent, EngineEvent, InternalEvent {
  final Track track;
  const AudioPlaybackFailed({
    required this.track,
  });

  @override
  String toString() => '${runtimeType}(track: ${track})';
}

@internal
class LocalTrackOptionsUpdatedEvent with TrackEvent, InternalEvent {
  final LocalTrack track;
  final LocalTrackOptions options;
  const LocalTrackOptionsUpdatedEvent({
    required this.track,
    required this.options,
  });

  @override
  String toString() => '${runtimeType}(track: ${track}, options: ${options})';
}

// Used to notify muted state from Track to TrackPublication.
@internal
class InternalTrackMuteUpdatedEvent with TrackEvent, InternalEvent {
  final Track track;
  final bool muted;
  final bool shouldSendSignal;
  const InternalTrackMuteUpdatedEvent({
    required this.track,
    required this.muted,
    required this.shouldSendSignal,
  });

  @override
  String toString() => '${runtimeType}(track: ${track}, muted: ${muted}, shouldSendSignal: ${shouldSendSignal})';
}

//
// Signal events
//

@internal
// Received a JoinResponse from the server.
class SignalJoinResponseEvent with SignalEvent, InternalEvent {
  final lk_rtc.JoinResponse response;
  const SignalJoinResponseEvent({
    required this.response,
  });

  @override
  String toString() => '${runtimeType}(response: ${response})';
}

@internal
// Received a ReconnectResponse from the server.
class SignalReconnectResponseEvent with SignalEvent, InternalEvent {
  final lk_rtc.ReconnectResponse response;
  const SignalReconnectResponseEvent({
    required this.response,
  });

  @override
  String toString() => '${runtimeType}(response: ${response})';
}

@internal
class SignalConnectivityChangedEvent with SignalEvent, InternalEvent {
  final List<ConnectivityResult> oldState;
  final List<ConnectivityResult> state;
  const SignalConnectivityChangedEvent({
    required this.oldState,
    required this.state,
  });

  @override
  String toString() => '${runtimeType}(oldState: ${oldState}, state: ${state})';
}

@internal
class EngineJoinResponseEvent with EngineEvent, InternalEvent {
  final lk_rtc.JoinResponse response;
  const EngineJoinResponseEvent({
    required this.response,
  });

  @override
  String toString() => '${runtimeType}(response: ${response})';
}

@internal
class EngineConnectingEvent with InternalEvent, EngineEvent {
  const EngineConnectingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineConnectedEvent with InternalEvent, SignalEvent, EngineEvent {
  const EngineConnectedEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineDisconnectedEvent with InternalEvent, EngineEvent {
  DisconnectReason? reason;
  EngineDisconnectedEvent({
    this.reason,
  });

  @override
  String toString() => '${runtimeType}(reason: ${reason})';
}

@internal
class EngineClosingEvent with InternalEvent, EngineEvent {
  const EngineClosingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineLocalTrackSubscribedEvent with InternalEvent, EngineEvent {
  final String trackSid;
  const EngineLocalTrackSubscribedEvent({
    required this.trackSid,
  });

  @override
  String toString() => '${runtimeType}(trackSid: ${trackSid})';
}

@internal
class EngineFullRestartingEvent with InternalEvent, EngineEvent {
  const EngineFullRestartingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineAttemptReconnectEvent with InternalEvent, EngineEvent {
  int attempt;
  int maxAttempts;
  int nextRetryDelaysInMs;
  EngineAttemptReconnectEvent({
    required this.attempt,
    required this.maxAttempts,
    required this.nextRetryDelaysInMs,
  });

  @override
  String toString() => '${runtimeType}'
      '(attempt: ${attempt}, maxAttempts: ${maxAttempts}, '
      'nextRetryDelaysInMs: ${nextRetryDelaysInMs})';
}

@internal
class EngineRestartedEvent with InternalEvent, EngineEvent {
  const EngineRestartedEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineReconnectingEvent with InternalEvent, EngineEvent {
  const EngineReconnectingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineResumedEvent with InternalEvent, EngineEvent {
  const EngineResumedEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class EngineResumingEvent with InternalEvent, EngineEvent {
  const EngineResumingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class SignalConnectedEvent with SignalEvent, InternalEvent {
  const SignalConnectedEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class SignalConnectingEvent with SignalEvent, InternalEvent {
  const SignalConnectingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class SignalReconnectingEvent with SignalEvent, InternalEvent {
  const SignalReconnectingEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class SignalReconnectedEvent with SignalEvent, InternalEvent, EngineEvent {
  const SignalReconnectedEvent();

  @override
  String toString() => '${runtimeType}()';
}

@internal
class SignalDisconnectedEvent with SignalEvent, InternalEvent {
  DisconnectReason? reason;
  SignalDisconnectedEvent({
    this.reason,
  });

  @override
  String toString() => '${runtimeType}(reason: ${reason})';
}

@internal
class SignalOfferEvent with SignalEvent, InternalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalOfferEvent({
    required this.sd,
  });

  @override
  String toString() => '${runtimeType}(sd: ${sd})';
}

@internal
class SignalAnswerEvent with SignalEvent, InternalEvent {
  final rtc.RTCSessionDescription sd;
  const SignalAnswerEvent({
    required this.sd,
  });

  @override
  String toString() => '${runtimeType}(sd: ${sd})';
}

@internal
class SignalTrickleEvent with SignalEvent, InternalEvent {
  final rtc.RTCIceCandidate candidate;
  final lk_rtc.SignalTarget target;
  const SignalTrickleEvent({
    required this.candidate,
    required this.target,
  });

  @override
  String toString() => '${runtimeType}(candidate: ${candidate}, target: ${target})';
}

@internal
// relayed by Engine
class SignalParticipantUpdateEvent with SignalEvent, InternalEvent {
  final List<lk_models.ParticipantInfo> participants;
  const SignalParticipantUpdateEvent({
    required this.participants,
  });

  @override
  String toString() => '${runtimeType}(participants: ${participants})';
}

@internal
class SignalConnectionQualityUpdateEvent with SignalEvent, InternalEvent {
  final List<lk_rtc.ConnectionQualityInfo> updates;
  const SignalConnectionQualityUpdateEvent({
    required this.updates,
  });

  @override
  String toString() => '${runtimeType}(updates: ${updates})';
}

@internal
class SignalLocalTrackPublishedEvent with SignalEvent, InternalEvent {
  final String cid;
  final lk_models.TrackInfo track;

  const SignalLocalTrackPublishedEvent({
    required this.cid,
    required this.track,
  });

  @override
  String toString() => '${runtimeType}(cid: ${cid}, track: ${track})';
}

@internal
class SignalTrackUnpublishedEvent with SignalEvent, InternalEvent {
  final String trackSid;

  const SignalTrackUnpublishedEvent({
    required this.trackSid,
  });

  @override
  String toString() => '${runtimeType}(trackSid: ${trackSid})';
}

@internal
class SignalLocalTrackSubscribedEvent with SignalEvent, InternalEvent {
  final String trackSid;

  const SignalLocalTrackSubscribedEvent({
    required this.trackSid,
  });

  @override
  String toString() => '${runtimeType}(trackSid: ${trackSid})';
}

@internal
class SignalRoomUpdateEvent with SignalEvent, InternalEvent {
  final lk_models.Room room;

  const SignalRoomUpdateEvent({required this.room});

  @override
  String toString() => '${runtimeType}(room: ${room})';
}

@internal
// Speaker update received through websocket
// relayed by Engine
class SignalSpeakersChangedEvent with SignalEvent, InternalEvent {
  final List<lk_models.SpeakerInfo> speakers;

  const SignalSpeakersChangedEvent({
    required this.speakers,
  });

  @override
  String toString() => '${runtimeType}(speakers: ${speakers})';
}

@internal
// Event received through data channel
class EngineActiveSpeakersUpdateEvent with EngineEvent, InternalEvent {
  final List<lk_models.SpeakerInfo> speakers;
  const EngineActiveSpeakersUpdateEvent({
    required this.speakers,
  });

  @override
  String toString() => '${runtimeType}(speakers: ${speakers})';
}

@internal
class SignalLeaveEvent with SignalEvent, InternalEvent {
  bool get canReconnect => request.canReconnect;
  lk_rtc.LeaveRequest_Action get action => request.action;
  lk_models.DisconnectReason get reason => request.reason;
  lk_rtc.RegionSettings? get regions => request.hasRegions() ? request.regions : null;
  final lk_rtc.LeaveRequest request;
  const SignalLeaveEvent({
    required this.request,
  });

  @override
  String toString() => '${runtimeType}'
      '(canReconnect: ${canReconnect}, action: ${action}, reason: ${reason}, regions: ${regions})';
}

@internal
class SignalRemoteMuteTrackEvent with SignalEvent, InternalEvent {
  final String sid;
  final bool muted;
  const SignalRemoteMuteTrackEvent({
    required this.sid,
    required this.muted,
  });

  @override
  String toString() => '${runtimeType}(sid: ${sid}, muted: ${muted})';
}

@internal
class SignalStreamStateUpdatedEvent with SignalEvent, InternalEvent {
  final List<lk_rtc.StreamStateInfo> updates;
  const SignalStreamStateUpdatedEvent({
    required this.updates,
  });

  @override
  String toString() => '${runtimeType}(updates: ${updates})';
}

@internal
class SignalSubscribedQualityUpdatedEvent with SignalEvent, InternalEvent {
  final String trackSid;
  final List<lk_rtc.SubscribedQuality> subscribedQualities;
  final List<lk_rtc.SubscribedCodec> subscribedCodecs;
  const SignalSubscribedQualityUpdatedEvent({
    required this.trackSid,
    required this.subscribedCodecs,
    required this.subscribedQualities,
  });

  @override
  String toString() => '${runtimeType}'
      '(trackSid: ${trackSid}, subscribedQualities: ${subscribedQualities}, '
      'subscribedCodecs: ${subscribedCodecs})';
}

@internal
class SignalSubscriptionPermissionUpdateEvent with SignalEvent, InternalEvent {
  final String participantSid;
  final String trackSid;
  final bool allowed;
  const SignalSubscriptionPermissionUpdateEvent({
    required this.participantSid,
    required this.trackSid,
    required this.allowed,
  });

  @override
  String toString() => '${runtimeType}'
      '(participantSid: ${participantSid}, trackSid: ${trackSid}, allowed: ${allowed})';
}

@internal
class SignalTokenUpdatedEvent with SignalEvent, InternalEvent {
  final String token;
  const SignalTokenUpdatedEvent({
    required this.token,
  });

  @override
  String toString() => '${runtimeType}(token: ${token})';
}

@internal
class SignalRequestResponseEvent with SignalEvent, InternalEvent {
  final lk_rtc.RequestResponse response;
  const SignalRequestResponseEvent({required this.response});

  @override
  String toString() => '${runtimeType}'
      '(requestId: ${response.requestId}, reason: ${response.reason})';
}

@internal
class SignalRoomMovedEvent with SignalEvent, InternalEvent {
  final lk_rtc.RoomMovedResponse response;
  const SignalRoomMovedEvent({required this.response});

  @override
  String toString() => '${runtimeType}(room: ${response.room.name})';
}

// ----------------------------------------------------------------------
// Engine events
// ----------------------------------------------------------------------

@internal
class EngineRequestResponseEvent with EngineEvent, InternalEvent {
  final lk_rtc.RequestResponse response;
  const EngineRequestResponseEvent({required this.response});

  @override
  String toString() => '${runtimeType}(requestId: ${response.requestId})';
}

@internal
class EngineRoomMovedEvent with EngineEvent, InternalEvent {
  final lk_rtc.RoomMovedResponse response;
  const EngineRoomMovedEvent({required this.response});

  @override
  String toString() => '${runtimeType}(room: ${response.room.name})';
}

@internal
class EngineTrackAddedEvent with EngineEvent, InternalEvent {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  const EngineTrackAddedEvent({
    required this.track,
    required this.stream,
    required this.receiver,
  });

  @override
  String toString() => '${runtimeType}(track: ${track}, stream: ${stream}, receiver: ${receiver})';
}

@internal
class EngineDataPacketReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.UserPacket packet;
  final lk_models.DataPacket_Kind kind;
  final String identity;
  const EngineDataPacketReceivedEvent({
    required this.packet,
    required this.kind,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}(packet: ${packet}, kind: ${kind}, identity: ${identity})';
}

@internal
class EngineTranscriptionReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.Transcription transcription;
  final String identity;
  const EngineTranscriptionReceivedEvent({
    required this.transcription,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}'
      '(transcription: ${transcription}, identity: ${identity})';
}

@internal
class EngineSipDtmfReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.SipDTMF dtmf;
  final String identity;
  const EngineSipDtmfReceivedEvent({
    required this.dtmf,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}(dtmf: ${dtmf}, identity: ${identity})';
}

@internal
class EngineRPCRequestReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcRequest request;
  String get requestId => request.id;
  final String identity;
  const EngineRPCRequestReceivedEvent({
    required this.request,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}(request: ${request}, identity: ${identity})';
}

@internal
class EngineRPCResponseReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcResponse response;
  String get requestId => response.requestId;
  final String identity;
  lk_models.RpcError? get error => response.error;
  String get payload => response.payload;
  const EngineRPCResponseReceivedEvent({
    required this.response,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}(response: ${response}, identity: ${identity})';
}

@internal
class EngineRPCAckReceivedEvent with EngineEvent, InternalEvent {
  final lk_models.RpcAck ack;
  String get requestId => ack.requestId;
  final String identity;
  const EngineRPCAckReceivedEvent({
    required this.ack,
    required this.identity,
  });

  @override
  String toString() => '${runtimeType}(ack: ${ack}, identity: ${identity})';
}

@internal
class EngineDataStreamHeaderEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Header header;
  final String identity;
  final EncryptionType encryptionType;
  const EngineDataStreamHeaderEvent({
    required this.header,
    required this.identity,
    required this.encryptionType,
  });

  @override
  String toString() => '${runtimeType}'
      '(header: ${header}, identity: ${identity}, encryptionType: ${encryptionType})';
}

@internal
class EngineDataStreamChunkEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Chunk chunk;
  final EncryptionType encryptionType;
  final String identity;
  const EngineDataStreamChunkEvent({
    required this.chunk,
    required this.identity,
    required this.encryptionType,
  });

  @override
  String toString() => '${runtimeType}'
      '(chunk: ${chunk}, identity: ${identity}, encryptionType: ${encryptionType})';
}

@internal
class EngineDataStreamTrailerEvent with EngineEvent, InternalEvent {
  final lk_models.DataStream_Trailer trailer;
  final String identity;
  final EncryptionType encryptionType;
  const EngineDataStreamTrailerEvent({
    required this.trailer,
    required this.identity,
    required this.encryptionType,
  });

  @override
  String toString() => '${runtimeType}'
      '(trailer: ${trailer}, identity: ${identity}, encryptionType: ${encryptionType})';
}

@internal
abstract class DataChannelStateUpdatedEvent with EngineEvent, InternalEvent {
  final bool isPrimary;
  final Reliability type;
  final rtc.RTCDataChannelState state;
  const DataChannelStateUpdatedEvent({
    required this.isPrimary,
    required this.type,
    required this.state,
  });

  @override
  String toString() => '${runtimeType}'
      '(isPrimary: ${isPrimary}, type: ${type}, state: ${state})';
}

@internal
class PublisherDataChannelStateUpdatedEvent extends DataChannelStateUpdatedEvent {
  PublisherDataChannelStateUpdatedEvent({
    required bool isPrimary,
    required Reliability type,
    required rtc.RTCDataChannelState state,
  }) : super(
          isPrimary: isPrimary,
          type: type,
          state: state,
        );
}

@internal
class SubscriberDataChannelStateUpdatedEvent extends DataChannelStateUpdatedEvent {
  SubscriberDataChannelStateUpdatedEvent({
    required bool isPrimary,
    required Reliability type,
    required rtc.RTCDataChannelState state,
  }) : super(
          isPrimary: isPrimary,
          type: type,
          state: state,
        );
}

@internal
class TrackEndedEvent with TrackEvent, InternalEvent {
  final Track track;
  const TrackEndedEvent({
    required this.track,
  });

  @override
  String toString() => '${runtimeType}(track: ${track})';
}
