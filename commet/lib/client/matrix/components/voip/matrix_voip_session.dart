import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/rtc_data_channel/matrix_rtc_data_channel_component.dart';
import 'package:commet/client/matrix/components/rtc_data_channel/matrix_rtc_data_media_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_stream.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:uuid/uuid.dart';

class MatrixVoipSession implements VoipSession {
  matrix.CallSession session;

  @override
  late Client client;

  final StreamController<void> _onStateChanged = StreamController.broadcast();

  List<StatsReport>? stats;

  RTCDataChannel? channel;

  DesktopCapturerSource? currentScreenshare;

  MatrixVoipSession(this.session, MatrixClient this.client) {
    session.onCallStateChanged.stream.listen((event) {
      _onStateChanged.add(null);
    });

    initStreams();
    session.onStreamAdd.stream.listen(onStreamAdded);
    session.onStreamRemoved.stream.listen(onStreamRemoved);

    final dataComponent = client.getComponent<MatrixRTCDataChannelComponent>();
    if (dataComponent != null) {
      session.pc?.onDataChannel =
          (channel) => dataComponent.dataChannelOpenedCallback(this, channel);
    }
  }

  @override
  String? get remoteUserId => session.remoteUserId;

  @override
  String get roomId => session.room.id;

  @override
  String get sessionId => "${client.identifier}_${session.callId}";

  @override
  Stream<void> get onStateChanged => _onStateChanged.stream;

  @override
  bool get isMicrophoneMuted => session.isMicrophoneMuted;

  @override
  String? get remoteUserName => session.remoteUser?.displayName;

  @override
  bool get supportsScreenshare => true;

  @override
  bool get isSharingScreen => session.localScreenSharingStream != null;

  @override
  bool get isCameraEnabled =>
      session.localUserMediaStream?.isVideoMuted() == false;

  @override
  VoipStream? get remoteUserMediaStream => session.remoteUserMediaStream != null
      ? MatrixVoipStream(session.remoteUserMediaStream!, this)
      : null;

  @override
  late List<VoipStream> streams;

  @override
  bool operator ==(Object other) {
    if (other is! MatrixVoipSession) return false;
    return sessionId == other.sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  VoipState get state {
    return switch (session.state) {
      matrix.CallState.kInviteSent => VoipState.outgoing,
      matrix.CallState.kCreateOffer => VoipState.outgoing,
      matrix.CallState.kCreateAnswer => VoipState.connecting,
      matrix.CallState.kConnecting => VoipState.connecting,
      matrix.CallState.kConnected => VoipState.connected,
      matrix.CallState.kRinging => VoipState.incoming,
      matrix.CallState.kEnded => VoipState.ended,
      _ => VoipState.unknown
    };
  }

  @override
  String get roomName => session.room.getLocalizedDisplayname();

  @override
  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false}) {
    return session.answer();
  }

  @override
  Future<void> declineCall() {
    return session.hangup(reason: matrix.CallErrorCode.userHangup);
  }

  @override
  Future<void> hangUpCall() {
    return session.hangup(reason: matrix.CallErrorCode.userHangup);
  }

  @override
  Future<void> setMicrophoneMute(bool state) {
    return session.setMicrophoneMuted(state);
  }

  Future<void> setCameraEnabled(bool state) {
    return session.setLocalVideoMuted(!state);
  }

  @override
  Future<void> updateStats() async {
    stats = await session.pc?.getStats();
  }

  @override
  Future<void> setScreenShare(DesktopCapturerSource source) async {
    var stream = await navigator.mediaDevices.getDisplayMedia({
      'video': {
        'deviceId': {'exact': source.id},
        'mandatory': {'frameRate': 30.0}
      }
    });

    currentScreenshare = source;

    await stopScreenshare();
    session.addLocalStream(stream, matrix.SDPStreamMetadataPurpose.Screenshare);
  }

  @override
  Future<void> stopScreenshare() async {
    for (var element in session.getLocalStreams.where((element) =>
        element.purpose == matrix.SDPStreamMetadataPurpose.Screenshare)) {
      await session.removeLocalStream(element);
    }
  }

  @override
  Future<void> setCamera(MediaDeviceInfo? device) async {
    if (session.localUserMediaStream!.stream!
            .getTracks()
            .any((element) => element.kind == "video") ==
        false) {
      await session.insertVideoTrackToAudioOnlyStream();
    }

    await session.setLocalVideoMuted(false);
  }

  @override
  Future<void> stopCamera() async {
    await session.setLocalVideoMuted(true);
  }

  void initStreams() {
    List<MatrixVoipStream> result = List.empty(growable: true);

    var s = List.from(session.getLocalStreams, growable: true);
    s.addAll(session.getRemoteStreams);

    for (var stream in s) {
      if (!shouldAddStream(stream)) {
        continue;
      }

      if (!result
          .any((element) => element.stream.stream?.id == stream.stream?.id)) {
        result.add(MatrixVoipStream(stream, this));
      }
    }

    streams = result;
  }

  bool shouldAddStream(stream) {
    if (stream.purpose == matrix.SDPStreamMetadataPurpose.Screenshare &&
        stream.videoMuted) {
      return false;
    }

    if (![
      matrix.SDPStreamMetadataPurpose.Screenshare,
      matrix.SDPStreamMetadataPurpose.Usermedia
    ].contains(stream.purpose)) {
      return false;
    }

    return true;
  }

  void onStreamAdded(matrix.WrappedMediaStream event) {
    if (shouldAddStream(event)) {
      streams.add(MatrixVoipStream(event, this));
      _onStateChanged.add(null);
    }
  }

  void onStreamRemoved(matrix.WrappedMediaStream event) {
    streams.removeWhere((e) => e.streamId == event.stream?.id);
    _onStateChanged.add(null);
  }
}
