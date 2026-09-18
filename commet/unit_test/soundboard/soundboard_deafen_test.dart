import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_call_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Soundboard sounds are played locally rather than carried over LiveKit, so
// deafening (which only zeroes the LiveKit stream volumes) used to leave other
// people's sounds fully audible.

class FakeVoipSession implements VoipSession {
  @override
  bool isDeafened = false;

  final StreamController<void> _stateChanged =
      StreamController.broadcast(sync: true);

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  Future<void> setDeafenedLocally(bool state) async {
    isDeafened = state;
    _stateChanged.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlayer implements SoundboardPlayer {
  final Map<String, double> volumes = {};
  final Set<String> playing = {};

  @override
  Future<void> start(String instanceId, String soundId) async {
    playing.add(instanceId);
  }

  @override
  Future<void> stop(String instanceId) async {
    playing.remove(instanceId);
  }

  @override
  Future<void> stopAll() async => playing.clear();

  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {
    volumes[instanceId] = volume;
  }

  @override
  bool isPlaying(String instanceId) => playing.contains(instanceId);
}

void main() {
  late FakeVoipSession session;
  late FakePlayer player;
  late SoundboardEngine engine;
  late SoundboardCallController controller;

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await preferences.init();
    await preferences.soundboardVolume.set(100.0);

    session = FakeVoipSession();
    player = FakePlayer();
    engine = SoundboardEngine(player: player);

    controller = SoundboardCallController(session);
    // init() downloads catalogs and builds a real player; the piece under test
    // is the listener volume, so wire a session up by hand instead.
    controller.soundboard = SoundboardSession(
      catalog: InMemorySoundboardCatalog(),
      engine: engine,
      transport: InMemorySoundboardTransport('test'),
      selfUserId: '@me:example.org',
    );
    engine.setVolume(controller.listenerVolume);
  });

  tearDown(() => controller.dispose());

  test('deafening silences sounds that are already playing', () async {
    engine.localTrigger(
        soundId: 'airhorn', senderId: '@other:example.org', eventId: 'e1');
    expect(player.volumes['e1'], 1.0);

    await session.setDeafenedLocally(true);

    expect(player.volumes['e1'], 0.0);
  });

  test('a sound that arrives while deafened never makes a noise', () async {
    await session.setDeafenedLocally(true);

    engine.localTrigger(
        soundId: 'airhorn', senderId: '@other:example.org', eventId: 'e1');

    expect(player.volumes['e1'], 0.0);
  });

  test('undeafening brings the volume back', () async {
    await session.setDeafenedLocally(true);
    engine.localTrigger(
        soundId: 'airhorn', senderId: '@other:example.org', eventId: 'e1');
    expect(player.volumes['e1'], 0.0);

    await session.setDeafenedLocally(false);

    expect(player.volumes['e1'], 1.0);
  });

  test('a volume set while deafened is remembered but stays silent', () async {
    await session.setDeafenedLocally(true);
    engine.localTrigger(
        soundId: 'airhorn', senderId: '@other:example.org', eventId: 'e1');

    await controller.setVolume01(0.5);
    expect(player.volumes['e1'], 0.0);

    await session.setDeafenedLocally(false);
    expect(player.volumes['e1'], 0.5);
  });
}
