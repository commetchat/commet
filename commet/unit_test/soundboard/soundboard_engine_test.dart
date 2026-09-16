import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:test/test.dart';

class FakePlayer implements SoundboardPlayer {
  /// soundIds in start order.
  final List<String> started = [];

  /// instanceIds in stop order.
  final List<String> stopped = [];
  final Map<String, double> volumes = {};
  final Set<String> playing = {};

  /// Runs synchronously inside [start], like a player that finds nothing
  /// to play before its first await.
  void Function(String instanceId)? onStart;

  @override
  Future<void> start(String instanceId, String soundId) async {
    started.add(soundId);
    playing.add(instanceId);
    onStart?.call(instanceId);
  }

  @override
  Future<void> stop(String instanceId) async {
    stopped.add(instanceId);
    playing.remove(instanceId);
  }

  @override
  Future<void> stopAll() async {
    stopped.addAll(playing);
    playing.clear();
  }

  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {
    volumes[instanceId] = volume;
  }

  @override
  bool isPlaying(String instanceId) => playing.contains(instanceId);
}

void main() {
  group('SoundboardEngine playback semantics', () {
    test('local trigger plays immediately and returns sendable event', () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      final event = engine.localTrigger(
        soundId: 'airhorn',
        senderId: '@a:x',
        eventId: 'e1',
      );
      expect(player.started, ['airhorn']);
      expect(event.soundId, 'airhorn');
      expect(event.eventId, 'e1');
    });

    test('own echo does not double-play', () async {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      final event = engine.localTrigger(
        soundId: 'airhorn',
        senderId: '@a:x',
        eventId: 'e1',
      );
      final played =
          await engine.onRemoteEvent(event, authenticatedSenderId: '@a:x');
      expect(played, isFalse);
      expect(player.started, ['airhorn']); // once
    });

    test('different sounds play simultaneously', () async {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player, nowMs: () => 1000);
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e1');
      engine.localTrigger(soundId: 'risada', senderId: '@a:x', eventId: 'e2');
      expect(engine.active.values.map((a) => a.soundId), ['airhorn', 'risada']);
      expect(player.started, ['airhorn', 'risada']);
    });

    test('same sound clicked twice plays two overlapping instances', () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e1');
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e2');
      expect(player.stopped, isEmpty);
      expect(player.started, ['airhorn', 'airhorn']);
      expect(player.playing, {'e1', 'e2'});
      expect(engine.active.keys, ['e1', 'e2']);
    });

    test('same sound from Bob overlaps Alice\'s instead of cutting it off',
        () async {
      var now = 1000;
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player, nowMs: () => now);
      engine.localTrigger(
          soundId: 'airhorn', senderId: '@alice:x', eventId: 'e1');
      now = 1500;
      final played = await engine.onRemoteEvent(
        const SoundboardEvent(
          soundId: 'airhorn',
          senderId: '@mallory:x', // spoofed hint
          eventId: 'e2',
          timestampMs: 1500,
        ),
        authenticatedSenderId: '@bob:x',
      );
      expect(played, isTrue);
      expect(player.stopped, isEmpty);
      expect(player.playing, {'e1', 'e2'});
      expect(engine.active['e1']!.senderId, '@alice:x');
      expect(engine.active['e2']!.senderId, '@bob:x');
    });

    test('an instance ending leaves the other instances of the sound', () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e1');
      engine.localTrigger(soundId: 'airhorn', senderId: '@b:x', eventId: 'e2');
      var notified = 0;
      engine.addListener(() => notified++);
      engine.onAudioCompleted('e1');
      expect(engine.active.keys, ['e2']);
      expect(player.stopped, isEmpty);
      expect(notified, 1);
    });

    test('an instance the player finishes while starting is not left active',
        () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      player.onStart = engine.onAudioCompleted;
      engine.localTrigger(soundId: 'deleted', senderId: '@a:x', eventId: 'e1');
      expect(engine.active, isEmpty);
    });

    test('a ninth concurrent instance stops the oldest one', () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      for (var i = 1; i <= 9; i++) {
        engine.localTrigger(
            soundId: 'airhorn', senderId: '@a:x', eventId: 'e$i');
      }
      expect(player.stopped, ['e1']);
      expect(engine.active.length, 8);
      expect(engine.active.keys.first, 'e2');
      expect(engine.active.keys.last, 'e9');
    });

    test('duplicate eventId plays once', () async {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player, nowMs: () => 1000);
      const e = SoundboardEvent(
        soundId: 'airhorn',
        senderId: '@a:x',
        eventId: 'dup',
        timestampMs: 1000,
      );
      expect(await engine.onRemoteEvent(e), isTrue);
      expect(await engine.onRemoteEvent(e), isFalse);
      expect(player.started, ['airhorn']);
    });

    test('stale event after reconnect is dropped (TTL)', () async {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player, nowMs: () => 100000);
      const e = SoundboardEvent(
        soundId: 'airhorn',
        senderId: '@a:x',
        eventId: 'old',
        timestampMs: 1000, // 99s old
      );
      expect(await engine.onRemoteEvent(e), isFalse);
      expect(player.started, isEmpty);
    });

    test('volume applies to current and future sounds; 0 mutes', () {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      engine.setVolume(0.0);
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e1');
      engine.localTrigger(soundId: 'airhorn', senderId: '@a:x', eventId: 'e2');
      expect(player.volumes, {'e1': 0.0, 'e2': 0.0});
      engine.setVolume(0.5);
      expect(player.volumes, {'e1': 0.5, 'e2': 0.5});
    });

    test('dispose (leaving the call) stops every instance', () async {
      final player = FakePlayer();
      final engine = SoundboardEngine(player: player);
      engine.localTrigger(soundId: 'a', senderId: '@a:x', eventId: 'e1');
      engine.localTrigger(soundId: 'a', senderId: '@b:x', eventId: 'e2');
      engine.localTrigger(soundId: 'b', senderId: '@a:x', eventId: 'e3');
      await engine.dispose();
      expect(engine.active, isEmpty);
      expect(player.playing, isEmpty);
    });
  });

  group('multi-client via InMemorySoundboardTransport', () {
    test('A triggers, B receives with sender attribution', () async {
      InMemorySoundboardTransport.resetAll();
      final pa = FakePlayer();
      final pb = FakePlayer();
      final ea = SoundboardEngine(player: pa, nowMs: () => 5000);
      final eb = SoundboardEngine(player: pb, nowMs: () => 5050);
      final ta = InMemorySoundboardTransport('@alice:x');
      final tb = InMemorySoundboardTransport('@bob:x');
      tb.incoming.listen((msg) => eb.onRemoteEvent(msg.event,
          authenticatedSenderId: msg.authenticatedSenderId));

      final event = ea.localTrigger(
          soundId: 'airhorn',
          senderId: '@alice:x',
          eventId: 'e1',
          soundDurationMs: 2000);
      await ta.send(event);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(pa.started, ['airhorn']); // local immediate
      expect(pb.started, ['airhorn']); // remote
      expect(eb.active['e1']!.senderId, '@alice:x');
      await ta.dispose();
      await tb.dispose();
      InMemorySoundboardTransport.resetAll();
    });
  });
}
