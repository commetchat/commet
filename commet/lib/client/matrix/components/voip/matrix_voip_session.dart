import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixVoipSession implements VoipSession {
  matrix.CallSession session;

  @override
  late Client client;

  final StreamController<void> _onStateChanged = StreamController.broadcast();

  MatrixVoipSession(this.session, MatrixClient this.client) {
    session.onCallStateChanged.stream.listen((event) {
      print("Matrix call state changed: ($event)");
      _onStateChanged.add(null);
    });

    session.onCallStreamsChanged.stream.listen((event) {
      print("Stream changed!");
    });
  }

  @override
  String? get remoteUserId => session.remotePartyId;

  @override
  String get roomId => session.room.id;

  @override
  String get sessionId => session.callId;

  @override
  Stream<void> get onStateChanged => _onStateChanged.stream;

  @override
  bool operator ==(Object other) {
    if (other is! MatrixVoipSession) return false;
    return sessionId == other.sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  VoipState get state {
    if (session.isRinging && !session.isOutgoing) {
      return VoipState.incoming;
    }

    switch (session.state) {
      case matrix.CallState.kConnecting:
      case matrix.CallState.kCreateAnswer:
        return VoipState.connecting;
      case matrix.CallState.kConnected:
        return VoipState.connected;
      default:
        break;
    }

    return VoipState.unknown;
  }

  @override
  String get roomName => session.room.getLocalizedDisplayname();

  @override
  Future<void> acceptCall() {
    print("Accepting call!");
    return session.answer();
  }

  @override
  Future<void> declineCall() {
    return session.hangup();
  }

  @override
  Future<void> hangUpCall() {
    return session.hangup();
  }

  @override
  Future<void> setMicrophoneMute(bool state) {
    return session.setMicrophoneMuted(state);
  }

  Future<void> setCameraEnabled(bool state) {
    return session.setLocalVideoMuted(!state);
  }

  @override
  bool get isMicrophoneMuted => session.isMicrophoneMuted;
}
