import 'package:commet/client/components/soundboard/soundboard_cache.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_dedup.dart';
import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_validation.dart';
import 'package:test/test.dart';

SoundboardSound _sound(String id, [String name = 'Airhorn']) => SoundboardSound(
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

  group('SoundboardSound state event content', () {
    List<Object?> leaves(Object? value) => switch (value) {
          Map() => value.values.expand(leaves).toList(),
          List() => value.expand(leaves).toList(),
          _ => [value],
        };

    test('has no floats, which homeservers reject in events', () {
      final json = _sound('s1').copyWith(normalizedGain: 0.891).toJson();
      expect(leaves(json).whereType<double>(), isEmpty);
      expect(json['normalized_gain_milli'], 891);
    });

    test('round-trips the gain', () {
      final sound = _sound('s1').copyWith(normalizedGain: 0.891);
      expect(SoundboardSound.fromJson(sound.toJson()).normalizedGain, 0.891);
    });

    test('still reads the float gain of earlier builds', () {
      final json = _sound('s1').toJson()
        ..remove('normalized_gain_milli')
        ..['normalized_gain'] = 0.5;
      expect(SoundboardSound.fromJson(json).normalizedGain, 0.5);
    });

    test('stores the admin volume as integer thousandths', () {
      final json = _sound('s1').copyWith(volume: 0.5).toJson();
      expect(leaves(json).whereType<double>(), isEmpty);
      expect(json['volume_milli'], 500);
      expect(SoundboardSound.fromJson(json).volume, 0.5);
    });

    test('a sound without admin volume plays at 100 %', () {
      final json = _sound('s1').toJson()..remove('volume_milli');
      expect(SoundboardSound.fromJson(json).volume, 1.0);
      expect(_sound('s1').volume, 1.0);
    });

    test('tolerates bad admin volume values', () {
      Map<String, dynamic> withVolume(Object? v) =>
          _sound('s1').toJson()..['volume_milli'] = v;
      expect(SoundboardSound.fromJson(withVolume('loud')).volume, 1.0);
      expect(SoundboardSound.fromJson(withVolume(-5)).volume, 0.0);
      expect(SoundboardSound.fromJson(withVolume(99999)).volume, 2.0);
    });

    test('gain combines normalization and admin volume', () {
      final sound = _sound('s1').copyWith(normalizedGain: 0.8, volume: 0.5);
      expect(sound.gain, closeTo(0.4, 1e-9));
      expect(sound.copyWith(name: 'x').volume, 0.5);
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
      final c = SoundboardSessionCache(maxEntries: 2, onEvict: evicted.add);
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
      expect(() => SoundboardValidator.sanitizeName('   '),
          throwsA(isA<SoundboardValidationError>()));
      expect(() => SoundboardValidator.sanitizeName('<b>x</b>'),
          throwsA(isA<SoundboardValidationError>()));
      expect(
          () => SoundboardValidator.sanitizeName(List.filled(65, 'a').join()),
          throwsA(isA<SoundboardValidationError>()));
    });

    test('accepts compound emoji, rejects multi-emoji', () {
      expect(SoundboardValidator.sanitizeEmoji('📢'), '📢');
      expect(SoundboardValidator.sanitizeEmoji('👨‍👩‍👧‍👦'), '👨‍👩‍👧‍👦');
      expect(SoundboardValidator.sanitizeEmoji('👍🏽'), '👍🏽');
      expect(SoundboardValidator.sanitizeEmoji('🇧🇷'), '🇧🇷');
      expect(() => SoundboardValidator.sanitizeEmoji('😂😂'),
          throwsA(isA<SoundboardValidationError>()));
      expect(() => SoundboardValidator.sanitizeEmoji('abc'),
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
