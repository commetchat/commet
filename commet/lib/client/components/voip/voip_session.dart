import 'dart:async';

import 'package:commet/client/client.dart';

enum VoipState { incoming, connecting, connected, unknown }

abstract class VoipSession {
  Client get client;

  String get sessionId;

  String get roomId;

  String? get remoteUserId;

  String? get remoteUserName;

  String get roomName;

  VoipState get state;

  bool get isMicrophoneMuted;

  Future<void> acceptCall();

  Future<void> declineCall();

  Future<void> hangUpCall();

  Stream<void> get onStateChanged;

  Future<void> setMicrophoneMute(bool state);
}
