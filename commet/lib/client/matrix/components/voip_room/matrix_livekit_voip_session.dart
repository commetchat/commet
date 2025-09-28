import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/organisms/call_view/screen_capture_source_dialog.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/src/desktop_capturer.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'package:webrtc_interface/src/mediadevices.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class MatrixLivekitVoipSession implements VoipSession {
  MatrixRoom room;
  lk.Room livekitRoom;
  MatrixLivekitVoipSession(this.room, this.livekitRoom);

  StreamController _stateChanged = StreamController.broadcast();

  @override
  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false}) {
    // TODO: implement acceptCall
    throw UnimplementedError();
  }

  @override
  Client get client => room.client;

  @override
  Future<void> declineCall() {
    throw UnimplementedError();
  }

  @override
  Future<void> hangUpCall() {
    throw UnimplementedError();
  }

  @override
  // TODO: implement isCameraEnabled
  bool get isCameraEnabled => false;

  @override
  // TODO: implement isMicrophoneMuted
  bool get isMicrophoneMuted => false;

  @override
  // TODO: implement isSharingScreen
  bool get isSharingScreen => false;

  @override
  // TODO: implement onStateChanged
  Stream<void> get onStateChanged => _stateChanged.stream;

  @override
  // TODO: implement remoteUserId
  String? get remoteUserId => null;

  @override
  // TODO: implement remoteUserMediaStream
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
  // TODO: implement sessionId
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
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    final src = (source as WebrtcScreencaptureSource).source;
    var track = await lk.LocalVideoTrack.createScreenShareTrack(
      lk.ScreenShareCaptureOptions(
          sourceId: src.id,
          maxFrameRate: 30.0,
          params: lk.VideoParametersPresets.screenShareH1080FPS30),
    );
    await livekitRoom.localParticipant?.publishVideoTrack(track);
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
  // TODO: implement streams
  List<VoipStream> get streams {
    var streams = List<VoipStream>.empty(growable: true);

    if (livekitRoom.localParticipant != null) {
      for (var entry
          in livekitRoom.localParticipant!.trackPublications.entries) {
        streams.add(
            MatrixLivekitVoipStream(entry.value, room.client.self!.identifier));
      }
    }

    for (var entry in livekitRoom.remoteParticipants.entries) {
      for (var stream in entry.value.trackPublications.entries) {
        String userId = entry.key;
        userId = userId.split(":").getRange(0, 2).join(":");

        streams.add(MatrixLivekitVoipStream(stream.value, userId));
      }
    }

    return streams;
    //  for(var participant in livekitRoom.remoteParticipants.entries) {

    //  };
  }

  @override
  // TODO: implement supportsScreenshare
  bool get supportsScreenshare => true;

  @override
  Future<void> updateStats() async {}

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) async {
    return WebrtcScreencaptureSource.showSelectSourcePrompt(context);
  }
}
