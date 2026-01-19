import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/android_screencapture_source.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/matrix/components/rtc_data_channel/matrix_rtc_data_channel_component.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_stream.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:matrix/matrix.dart' as matrix;

class MatrixVoipSession implements VoipSession {
  matrix.CallSession session;

  @override
  late Client client;

  final StreamController<void> _onStateChanged = StreamController.broadcast();
  final StreamController<void> _onVolumeChanged = StreamController.broadcast();

  List<StatsReport>? stats;

  RTCDataChannel? channel;

  bool _active = true;

  ScreenCaptureSource? currentScreenshare;

  final StreamController<VoipState> _onConnectionChanged =
      StreamController.broadcast();

  @override
  Stream<VoipState> get onConnectionStateChanged => _onConnectionChanged.stream;

  MatrixVoipSession(this.session, MatrixClient this.client) {
    session.onCallStateChanged.stream.listen((event) {
      _onStateChanged.add(null);
      _onConnectionChanged.add(state);
    });

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (state == VoipState.ended) timer.cancel();
      _onVolumeChanged.add(());
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
      {bool withMicrophone = false, bool withCamera = false}) async {
    WebrtcDefaultDevices.selectOutputDevice();

    var defaultStream = await WebrtcDefaultDevices.getDefaultMicrophone();

    if (defaultStream != null) {
      return session.answerWithStreams([
        matrix.WrappedMediaStream(
            stream: defaultStream,
            room: session.room,
            participant: session.localParticipant!,
            purpose: matrix.SDPStreamMetadataPurpose.Usermedia,
            client: session.room.client,
            audioMuted: false,
            videoMuted: true,
            isGroupCall: false,
            voip: session.voip),
      ]);
    } else {
      return session.answer();
    }
  }

  @override
  Future<void> declineCall() {
    return session.hangup(reason: matrix.CallErrorCode.userHangup);
  }

  @override
  Future<void> hangUpCall() {
    _active = false;
    return session.hangup(reason: matrix.CallErrorCode.userHangup);
  }

  @override
  Future<void> setMicrophoneMute(bool state) {
    return session.setMicrophoneMuted(state);
  }

  Future<void> setCameraEnabled(bool state) {
    return session.setLocalVideoMuted(!state);
  }

  DateTime _lastUpdatedStats = DateTime.fromMicrosecondsSinceEpoch(0);
  @override
  Future<void> updateStats() async {
    var now = DateTime.now();
    var diff = now.difference(_lastUpdatedStats).inMilliseconds;

    if (diff < 200) {
      return;
    }

    if (_active) {
      stats = await session.pc?.getStats();
      _lastUpdatedStats = now;
    }
  }

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    MediaStream? stream;

    if (source is WebrtcAndroidScreencaptureSource) {
      stream = await webrtc.navigator.mediaDevices.getDisplayMedia({
        'video': {
          'mandatory': {'frameRate': 30.0}
        }
      });
    }

    if (source is WebrtcScreencaptureSource) {
      stream = await webrtc.navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': 1280,
          'height': 720,
          'deviceId': {'exact': source.source.id},
          'mandatory': {'frameRate': 30.0}
        }
      });
    }

    if (stream != null) {
      currentScreenshare = source;
      await stopScreenshare();
      session.addLocalStream(
          stream, matrix.SDPStreamMetadataPurpose.Screenshare);
    }
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

    var s = List<matrix.WrappedMediaStream>.from(session.getLocalStreams,
        growable: true);
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

  bool shouldAddStream(matrix.WrappedMediaStream stream) {
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

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) async {
    return WebrtcScreencaptureSource.showSelectSourcePrompt(context);
  }

  @override
  double get generalAudioLevel => (remoteUserMediaStream?.audiolevel ?? 0) * 3;

  @override
  Stream<void> get onUpdateVolumeVisualizers => _onVolumeChanged.stream;
}
