import 'package:commet/config/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/src/mediadevices.dart';
import 'package:webrtc_interface/src/rtc_peerconnection.dart';
import 'package:webrtc_interface/src/rtc_video_renderer.dart';

class MatrixVoipPlugin implements WebRTCDelegate {
  @override
  // TODO: implement canHandleNewCall
  bool get canHandleNewCall => throw UnimplementedError();

  @override
  Future<RTCPeerConnection> createPeerConnection(
      Map<String, dynamic> configuration,
      [Map<String, dynamic> constraints = const {}]) {
    // TODO: implement createPeerConnection
    throw UnimplementedError();
  }

  @override
  VideoRenderer createRenderer() {
    throw UnimplementedError();
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    print("handleCallEnded");
  }

  @override
  Future<void> handleGroupCallEnded(GroupCall groupCall) async {
    print("handleGroupCallEnded");
  }

  @override
  Future<void> handleMissedCall(CallSession session) async {
    print("handleMissedCall");
  }

  @override
  Future<void> handleNewCall(CallSession session) async {
    print("handleNewCall");
  }

  @override
  Future<void> handleNewGroupCall(GroupCall groupCall) async {
    print("handleNewGroupCall");
  }

  @override
  bool get isWeb => PlatformUtils.isWeb;

  @override
  MediaDevices get mediaDevices => throw UnimplementedError();

  @override
  Future<void> playRingtone() async {
    print("play ringtone!");
  }

  @override
  Future<void> stopRingtone() async {
    print("Stop playing ringtone");
  }
}
