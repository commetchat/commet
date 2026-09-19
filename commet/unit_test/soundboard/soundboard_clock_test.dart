import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_clock.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:test/test.dart';

// Someone whose clock was hours off (a dual-boot machine) could neither hear
// the soundboard nor be heard: every trigger looked stale or from the future
// to the other side.

class _Player implements SoundboardPlayer {
  final List<String> started = [];
  @override
  Future<void> start(String instanceId, String soundId) async =>
      started.add(soundId);
  @override
  Future<void> stop(String instanceId) async {}
  @override
  Future<void> stopAll() async {}
  @override
  Future<void> setVolumeFor(String instanceId, double volume) async {}
  @override
  bool isPlaying(String instanceId) => false;
}

const _threeHours = 3 * 60 * 60 * 1000;

SoundboardEvent _play(String id, int timestampMs) => SoundboardEvent(
      soundId: 'airhorn',
      senderId: '@skewed:x',
      eventId: id,
      timestampMs: timestampMs,
    );

SoundboardSound _airhorn() => const SoundboardSound(
      soundId: 'airhorn',
      name: 'Airhorn',
      emoji: SoundboardEmoji.unicode('📯'),
      mediaUri: 'mxc://h/airhorn',
      mimeType: 'audio/mpeg',
      durationMs: 1500,
      normalizedGain: 1.0,
    );

void main() {
  group('Engine with a sender whose clock is hours off', () {
    const now = 10 * _threeHours;

    for (final (name, skew) in [
      ('behind', -_threeHours),
      ('ahead', _threeHours),
    ]) {
      test('$name: plays once their clock is known', () async {
        final player = _Player();
        final engine = SoundboardEngine(player: player, nowMs: () => now);

        // Unknown clock: the wall-clock check is all there is.
        expect(await engine.onRemoteEvent(_play('first', now + skew)), isFalse);

        engine.clocks.observe('@skewed:x', now + skew - 40, now);
        expect(await engine.onRemoteEvent(_play('second', now + skew)), isTrue);
        expect(player.started, ['airhorn']);
      });

      test('$name: a trigger held back across a reconnect is still dropped',
          () async {
        final engine = SoundboardEngine(player: _Player(), nowMs: () => now);
        engine.clocks.observe('@skewed:x', now + skew, now);

        // Sent 10 s ago by their clock.
        expect(await engine.onRemoteEvent(_play('late', now + skew - 10000)),
            isFalse);
      });
    }

    test('a sample stops counting after the window', () {
      final clocks = SoundboardClocks(window: const Duration(minutes: 10));
      clocks.observe('@a:x', 0, 50);
      expect(clocks.offsetOf('@a:x', 50), 50);
      expect(clocks.offsetOf('@a:x', 11 * 60 * 1000), isNull);
    });
  });

  group('Clock messages', () {
    test('round trip through JSON; older clients reject them', () {
      const clock = SoundboardEvent.clock(
          senderId: '@a:x', eventId: 'c1', timestampMs: 5, wantsReply: true);
      final parsed = SoundboardEvent.tryParse(clock.toJson())!;
      expect(parsed.isClock, isTrue);
      expect(parsed.wantsReply, isTrue);
      expect(parsed.timestampMs, 5);
      // What a client from before clock messages checks first.
      expect(clock.toJson()['type'], isNot(SoundboardEvent.typePlay));
    });

    test('play events still need a sound', () {
      expect(
          SoundboardEvent.tryParse({
            'type': SoundboardEvent.typePlay,
            'event_id': 'e',
            'timestamp': 1,
          }),
          isNull);
    });
  });

  test('two clients three hours apart hear each other', () async {
    InMemorySoundboardTransport.resetAll();
    final realNow = DateTime.now().millisecondsSinceEpoch;
    final playerA = _Player();
    final playerB = _Player();

    final a = SoundboardSession(
      catalog: InMemorySoundboardCatalog([_airhorn()]),
      engine: SoundboardEngine(player: playerA),
      transport: InMemorySoundboardTransport('@a:x'),
      selfUserId: '@a:x',
    );
    // B's clock is three hours behind.
    final b = SoundboardSession(
      catalog: InMemorySoundboardCatalog([_airhorn()]),
      engine: SoundboardEngine(
          player: playerB,
          nowMs: () => DateTime.now().millisecondsSinceEpoch - _threeHours),
      transport: InMemorySoundboardTransport('@b:x'),
      selfUserId: '@b:x',
    );
    addTearDown(InMemorySoundboardTransport.resetAll);

    await a.init();
    // B joins; A answers B's clock message with its own.
    await b.init();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(a.engine.clocks.offsetOf('@b:x', realNow + 100), isNotNull);
    expect(b.engine.clocks.offsetOf('@a:x', realNow - _threeHours + 100),
        isNotNull);

    await a.trigger('airhorn');
    await b.trigger('airhorn');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Each played its own click and the other's.
    expect(playerA.started, ['airhorn', 'airhorn']);
    expect(playerB.started, ['airhorn', 'airhorn']);
  });
}
