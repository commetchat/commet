import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_stream.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixVoipSession implements VoipSession {
  matrix.CallSession session;

  @override
  late Client client;

  final StreamController<void> _onStateChanged = StreamController.broadcast();

  List<StatsReport>? stats;

  MatrixVoipSession(this.session, MatrixClient this.client) {
    session.onCallStateChanged.stream.listen((event) {
      _onStateChanged.add(null);
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
  VoipStream? get remoteUserMediaStream => session.remoteUserMediaStream != null
      ? MatrixVoipStream(session.remoteUserMediaStream!, this)
      : null;

  @override
  List<VoipStream> get streams {
    List<MatrixVoipStream> result = List.empty(growable: true);
    for (var stream in session.streams) {
      if (stream.purpose == matrix.SDPStreamMetadataPurpose.Screenshare &&
          stream.videoMuted) {
        continue;
      }

      if (!result
          .any((element) => element.stream.stream?.id == stream.stream?.id)) {
        result.add(MatrixVoipStream(stream, this));
      }
    }

    return result;
  }

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

  @override
  String? get remoteUserName => session.remoteUser?.displayName;

  @override
  Future<void> updateStats() async {
    stats = await session.pc?.getStats();
  }
}
