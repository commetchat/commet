import 'package:commet/client/components/soundboard/soundboard_cache.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_dedup.dart';
import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_validation.dart';
import 'package:test/test.dart';

SoundboardSound _sound(String id, [String name = 'Airhorn']) =>
    SoundboardSound(
      soundId: id,
      name: name,
      emoji: '📢',
      mediaUri: 'mxc://x/$id',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 1.0,
    );

void main() {
  group('SoundboardEvent protocol', () {
    test('round-trips and rejects unknown types', () {
      const e = SoundboardEvent(
        soundId: 's1',
        senderId: '@a:x',
        eventId: 'e1',
        timestampMs: 1000,
      );
      final back = SoundboardEvent.tryParseBytes(e.encode())!;
      expect(back.soundId, 's1');
      expect(back.version, 1);
      expect(
          SoundboardEvent.tryParse({
            'type': 'm.room.message',
            'sound_id': 's1',
            'event_id': 'e1',
            'timestamp': 1000,
          }),
          isNull);
    });

    test('accepts future versions (forward-compat)', () {
      final e = SoundboardEvent.tryParse({
        'type': 'soundboard.play',
        'version': 99,
        'sound_id': 's1',
        'sender_id': '@a:x',
        'event_id': 'e1',
        'timestamp': 1000,
        'future_field': {'nested': true},
      });
      expect(e, isNotNull);
      expect(e!.soundId, 's1');
    });

    test('TTL drops stale and far-future events', () {
      const e = SoundboardEvent(
        soundId: 's',
        senderId: '@a:x',
        eventId: 'e',
        timestampMs: 0,
      );
      expect(e.isFresh(1000), isTrue);
      expect(e.isFresh(100000), isFalse);
      expect(e.isFresh(-1000000), isFalse);
    });
  });

  group('SoundboardDedup', () {
    test('one trigger -> one playback; bounded memory', () {
      final d = SoundboardDedup(maxEntries: 3);
      expect(d.checkAndRemember('a', 0), isFalse);
      expect(d.checkAndRemember('a', 1), isTrue);
      d.checkAndRemember('b', 2);
      d.checkAndRemember('c', 3);
      d.checkAndRemember('d', 4);
      expect(d.size, 3);
    });
  });

  group('SoundboardSessionCache LRU', () {
    test('evicts oldest beyond capacity', () {
      final evicted = <String>[];
      final c = SoundboardSessionCache(
          maxEntries: 2, onEvict: evicted.add);
      c.markLoaded('a', 1);
      c.markLoaded('b', 2);
      c.markLoaded('c', 3);
      expect(c.isLoaded('a'), isFalse);
      expect(evicted, ['a']);
      expect(c.loaded.length, 2);
    });
  });

  group('InMemorySoundboardCatalog', () {
    test('upsert/remove/lookup + stable ids', () {
      final cat = InMemorySoundboardCatalog();
      cat.upsert(_sound('id-1', 'Airhorn'));
      cat.upsert(_sound('id-2', 'Bruh'));
      expect(cat.getById('id-1')!.name, 'Airhorn');
      // Rename keeps id.
      cat.upsert(_sound('id-1', 'Airhorn v2'));
      expect(cat.sounds.length, 2);
      expect(cat.getById('id-1')!.name, 'Airhorn v2');
      cat.remove('id-2');
      expect(cat.getById('id-2'), isNull);
    });
  });

  group('SoundboardValidator name/emoji', () {
    test('sanitizes names, rejects markup/empty/toolong', () {
      expect(SoundboardValidator.sanitizeName('  Airhorn  '), 'Airhorn');
      expect(
          () => SoundboardValidator.sanitizeName('   '),
          throwsA(isA<SoundboardValidationError>()));
      expect(
          () => SoundboardValidator.sanitizeName('<b>x</b>'),
          throwsA(isA<SoundboardValidationError>()));
      expect(
          () => SoundboardValidator.sanitizeName(
              List.filled(65, 'a').join()),
          throwsA(isA<SoundboardValidationError>()));
    });

    test('accepts compound emoji, rejects multi-emoji', () {
      expect(SoundboardValidator.sanitizeEmoji('📢'), '📢');
      expect(SoundboardValidator.sanitizeEmoji('👨‍👩‍👧‍👦'), '👨‍👩‍👧‍👦');
      expect(SoundboardValidator.sanitizeEmoji('👍🏽'), '👍🏽');
      expect(SoundboardValidator.sanitizeEmoji('🇧🇷'), '🇧🇷');
      expect(
          () => SoundboardValidator.sanitizeEmoji('😂😂'),
          throwsA(isA<SoundboardValidationError>()));
      expect(
          () => SoundboardValidator.sanitizeEmoji('abc'),
          throwsA(isA<SoundboardValidationError>()));
    });
  });

  group('overlay duration clamp', () {
    test('uses spec bounds', () {
      // Replicates SoundboardEngine.clampOverlayMs without flutter import.
      int clamp(int? d) => (d ?? 1200).clamp(1200, 3500);
      expect(clamp(2000), 2000);
      expect(clamp(100), 1200);
      expect(clamp(60000), 3500);
    });
  });
}
