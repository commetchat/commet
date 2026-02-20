import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/generated/rust/api/livekit/livekit_session_manager.dart';
import 'package:flutter/src/painting/box_fit.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:webrtc_interface/src/mediadevices.dart';

class MatrixLivekitRustSession implements VoipSession {
  MatrixRoom room;
  LivekitSessionReference session;

  MatrixLivekitRustSession(this.room, this.session);

  final StreamController _stateChanged = StreamController.broadcast();

  final StreamController<VoipState> _onConnectionChanged =
      StreamController.broadcast();

  final StreamController<void> _onVolumeChanged = StreamController.broadcast();

  @override
  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false}) {
    throw UnimplementedError();
  }

  @override
  Client get client => room.client;

  @override
  Future<void> declineCall() {
    throw UnimplementedError();
  }

  @override
  double get generalAudioLevel => 0;

  @override
  Future<void> hangUpCall() {
    throw UnimplementedError();
  }

  @override
  bool get isCameraEnabled => false;

  @override
  bool get isMicrophoneMuted => false;

  @override
  bool get isSharingScreen => false;

  @override
  Stream<VoipState> get onConnectionStateChanged => _onConnectionChanged.stream;

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  @override
  Stream<void> get onUpdateVolumeVisualizers => _onVolumeChanged.stream;

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  String? get remoteUserId => null;

  @override
  VoipStream? get remoteUserMediaStream => null;

  @override
  // TODO: implement remoteUserName
  String? get remoteUserName => null;

  @override
  // TODO: implement roomId
  String get roomId => room.identifier;

  @override
  // TODO: implement roomName
  String get roomName => room.displayName;

  @override
  String get sessionId => "";

  @override
  Future<void> setCamera(MediaDeviceInfo? device) {
    // TODO: implement setCamera
    throw UnimplementedError();
  }

  @override
  Future<void> setMicrophoneMute(bool state) {
    // TODO: implement setMicrophoneMute
    throw UnimplementedError();
  }

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) {
    // TODO: implement setScreenShare
    throw UnimplementedError();
  }

  @override
  // TODO: implement state
  VoipState get state => VoipState.connected;

  @override
  Future<void> stopCamera() {
    // TODO: implement stopCamera
    throw UnimplementedError();
  }

  @override
  Future<void> stopScreenshare() {
    // TODO: implement stopScreenshare
    throw UnimplementedError();
  }

  @override
  List<VoipStream> get streams =>
      session.remoteTracks().map((i) => LivekitRustVoipStream(i)).toList();

  @override
  bool get supportsScreenshare => false;

  @override
  Future<void> updateStats() async {}
}

class LivekitRustVoipStream implements VoipStream {
  LivekitTrack track;

  LivekitRustVoipStream(this.track);

  @override
  double? get aspectRatio => 1;

  @override
  double get audiolevel => 1;

  @override
  Widget? buildVideoRenderer(BoxFit fit, Key key) {
    return null;
  }

  @override
  VoipStreamDirection get direction => VoipStreamDirection.incoming;

  @override
  bool get isMuted => false;

  @override
  String get label => "";

  @override
  Stream<void> get onStreamChanged => Stream.empty();

  @override
  String get streamId => track.id;

  @override
  String get streamUserId => track.owner.split(":").sublist(0, 1).join(":");

  @override
  VoipStreamType get type => VoipStreamType.audio;
}
