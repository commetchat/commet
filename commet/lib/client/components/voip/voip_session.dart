import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_stream.dart';

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

  VoipStream? get remoteUserMediaStream;

  List<VoipStream> get streams;

  Future<void> acceptCall();

  Future<void> declineCall();

  Future<void> hangUpCall();

  Stream<void> get onStateChanged;

  Future<void> setMicrophoneMute(bool state);

  Future<void> updateStats();
}
