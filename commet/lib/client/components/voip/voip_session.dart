import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum VoipState {
  incoming,
  connecting,
  connected,
  unknown,
  outgoing,
  ended,
}

abstract class ScreenCaptureSource {}

abstract class VoipSession {
  Client get client;

  String get sessionId;

  String get roomId;

  String? get remoteUserId;

  String? get remoteUserName;

  String get roomName;

  VoipState get state;

  bool get isMicrophoneMuted;

  bool get supportsScreenshare;

  bool get isSharingScreen;

  bool get isCameraEnabled;

  VoipStream? get remoteUserMediaStream;

  List<VoipStream> get streams;

  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false});

  Future<void> declineCall();

  Future<void> hangUpCall();

  Stream<void> get onStateChanged;

  Future<void> setMicrophoneMute(bool state);

  Future<void> updateStats();

  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context);

  Future<void> setScreenShare(ScreenCaptureSource source);

  Future<void> stopScreenshare();

  Future<void> setCamera(MediaDeviceInfo? device);

  Future<void> stopCamera();
}
