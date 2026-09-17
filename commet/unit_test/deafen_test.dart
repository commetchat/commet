import 'dart:async';
import 'package:commet/client/call_manager.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:test/test.dart';

class FakeVoipSession implements VoipSession {
  @override
  bool isMicrophoneMuted = false;

  @override
  bool isDeafened = false;

  final List<FakeVoipStream> _streams = [];

  @override
  List<VoipStream> get streams => _streams;

  final StreamController<void> _stateChanged = StreamController.broadcast();
  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  final StreamController<VoipState> _connectionChanged =
      StreamController.broadcast();
  @override
  Stream<VoipState> get onConnectionStateChanged => _connectionChanged.stream;

  final StreamController<void> _volumeChanged = StreamController.broadcast();
  @override
  Stream<void> get onUpdateVolumeVisualizers => _volumeChanged.stream;

  @override
  Future<void> setMicrophoneMute(bool state) async {
    isMicrophoneMuted = state;
    // Se o usuário tentar desmutar o microfone enquanto ensurdecido,
    // o deafen deve ser cancelado (comportamento Discord)
    if (!state && isDeafened) {
      isDeafened = false;
      _restoreStreamsVolume();
    }
    _stateChanged.add(null);
  }

  @override
  Future<void> setDeafened(bool state) async {
    isDeafened = state;
    if (state) {
      isMicrophoneMuted = true;
      _silenceStreamsVolume();
    } else {
      isMicrophoneMuted = false;
      _restoreStreamsVolume();
    }
    _stateChanged.add(null);
  }

  void _silenceStreamsVolume() {
    for (var stream in _streams) {
      if (stream.direction == VoipStreamDirection.incoming) {
        stream.currentPlayingVolume = 0.0;
      }
    }
  }

  void _restoreStreamsVolume() {
    for (var stream in _streams) {
      if (stream.direction == VoipStreamDirection.incoming) {
        stream.currentPlayingVolume = stream.userConfiguredVolume;
      }
    }
  }

  void addStream(FakeVoipStream stream) {
    _streams.add(stream);
    if (isDeafened && stream.direction == VoipStreamDirection.incoming) {
      stream.currentPlayingVolume = 0.0;
    } else {
      stream.currentPlayingVolume = stream.userConfiguredVolume;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVoipStream implements VoipStream {
  @override
  final VoipStreamDirection direction;
  @override
  final VoipStreamType type;
  @override
  final String streamUserId;

  double userConfiguredVolume = 1.0;
  double currentPlayingVolume = 1.0;

  FakeVoipStream({
    required this.direction,
    required this.type,
    required this.streamUserId,
    this.userConfiguredVolume = 1.0,
  }) {
    currentPlayingVolume = userConfiguredVolume;
  }

  @override
  Future<void> setVolume(double volume) async {
    userConfiguredVolume = volume;
    currentPlayingVolume = volume;
  }

  @override
  double get volume => currentPlayingVolume;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group("VoipSession Deafen Contract", () {
    test("Deafening mutes microphone and silences all incoming audio streams",
        () async {
      final session = FakeVoipSession();
      final stream1 = FakeVoipStream(
        direction: VoipStreamDirection.incoming,
        type: VoipStreamType.audio,
        streamUserId: "@user1:matrix.org",
        userConfiguredVolume: 0.8,
      );
      session.addStream(stream1);

      expect(session.isDeafened, isFalse);
      expect(session.isMicrophoneMuted, isFalse);
      expect(stream1.currentPlayingVolume, equals(0.8));

      await session.setDeafened(true);

      expect(session.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);
      expect(stream1.currentPlayingVolume, equals(0.0));
      // Garante que o volume configurado pelo usuário não foi destruído
      expect(stream1.userConfiguredVolume, equals(0.8));
    });

    test("Undeafening restores microphone and incoming stream volume",
        () async {
      final session = FakeVoipSession();
      final stream1 = FakeVoipStream(
        direction: VoipStreamDirection.incoming,
        type: VoipStreamType.audio,
        streamUserId: "@user1:matrix.org",
        userConfiguredVolume: 0.75,
      );
      session.addStream(stream1);

      await session.setDeafened(true);
      expect(session.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);
      expect(stream1.currentPlayingVolume, equals(0.0));

      await session.setDeafened(false);
      expect(session.isDeafened, isFalse);
      expect(session.isMicrophoneMuted, isFalse);
      expect(stream1.currentPlayingVolume, equals(0.75));
    });

    test("Incoming audio streams added while deafened are immediately silenced",
        () async {
      final session = FakeVoipSession();
      await session.setDeafened(true);

      final stream2 = FakeVoipStream(
        direction: VoipStreamDirection.incoming,
        type: VoipStreamType.audio,
        streamUserId: "@user2:matrix.org",
        userConfiguredVolume: 1.0,
      );
      session.addStream(stream2);

      expect(stream2.currentPlayingVolume, equals(0.0));
      expect(stream2.userConfiguredVolume, equals(1.0));

      await session.setDeafened(false);
      expect(stream2.currentPlayingVolume, equals(1.0));
    });

    test(
        "Unmuting microphone while deafened automatically cancels deafen (Discord rule)",
        () async {
      final session = FakeVoipSession();
      final stream1 = FakeVoipStream(
        direction: VoipStreamDirection.incoming,
        type: VoipStreamType.audio,
        streamUserId: "@user1:matrix.org",
        userConfiguredVolume: 0.9,
      );
      session.addStream(stream1);

      await session.setDeafened(true);
      expect(session.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);

      // Usuário tenta desmutar o microfone
      await session.setMicrophoneMute(false);

      expect(session.isMicrophoneMuted, isFalse);
      expect(session.isDeafened, isFalse);
      expect(stream1.currentPlayingVolume, equals(0.9));
    });
  });

  group("CallManager Deafen Coordination", () {
    test("deafen(), undeafen() and toggleDeafen() control active sessions", () {
      final clientManager = ClientManager();
      final callManager = CallManager(clientManager);
      final session = FakeVoipSession();
      callManager.currentSessions.add(session);

      expect(callManager.isDeafened, isFalse);

      callManager.deafen();
      expect(callManager.isDeafened, isTrue);
      expect(session.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);

      callManager.undeafen();
      expect(callManager.isDeafened, isFalse);
      expect(session.isDeafened, isFalse);
      expect(session.isMicrophoneMuted, isFalse);

      callManager.toggleDeafen();
      expect(callManager.isDeafened, isTrue);

      callManager.toggleDeafen();
      expect(callManager.isDeafened, isFalse);
    });

    test(
        "CallManager unmute() and toggleMute() un-deafens when deafened (Discord rule)",
        () {
      final clientManager = ClientManager();
      final callManager = CallManager(clientManager);
      final session = FakeVoipSession();
      callManager.currentSessions.add(session);

      callManager.deafen();
      expect(callManager.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);

      // Desmutar pelo CallManager deve remover deafen e desmutar mic
      callManager.unmute();
      expect(callManager.isDeafened, isFalse);
      expect(session.isDeafened, isFalse);
      expect(session.isMicrophoneMuted, isFalse);

      // Novamente com toggleMute()
      callManager.deafen();
      expect(callManager.isDeafened, isTrue);
      expect(session.isMicrophoneMuted, isTrue);

      callManager
          .toggleMute(); // Estava mutado por deafen -> deve desmutar e des-ensurdecer
      expect(callManager.isDeafened, isFalse);
      expect(session.isDeafened, isFalse);
      expect(session.isMicrophoneMuted, isFalse);
    });
  });
}
