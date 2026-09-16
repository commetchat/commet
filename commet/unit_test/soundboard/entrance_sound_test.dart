import 'package:commet/client/components/soundboard/entrance_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:test/test.dart';

SoundboardSound _s(String id) => SoundboardSound(
      soundId: id,
      name: 'S $id',
      emoji: const SoundboardEmoji.unicode('🐴'),
      mediaUri: 'mxc://h/$id',
      mimeType: 'audio/mpeg',
      durationMs: 1500,
      normalizedGain: 1.0,
    );

void main() {
  group('pickEntranceSound', () {
    final catalog = InMemorySoundboardCatalog([_s('horse')]);

    test('plays the chosen sound when the room Space has it', () {
      expect(
        pickEntranceSound(
          choice: const EntranceSoundChoice(soundId: 'horse'),
          roomSpaceIds: const ['!space:x'],
          catalog: catalog,
          deafened: false,
        ),
        'horse',
      );
    });

    test('plays nothing when the room Space does not have the sound', () {
      expect(
        pickEntranceSound(
          choice: const EntranceSoundChoice(soundId: 'deleted'),
          roomSpaceIds: const ['!space:x'],
          catalog: catalog,
          deafened: false,
        ),
        isNull,
      );
    });

    test('plays nothing when the user joins deafened', () {
      expect(
        pickEntranceSound(
          choice: const EntranceSoundChoice(soundId: 'horse'),
          roomSpaceIds: const ['!space:x'],
          catalog: catalog,
          deafened: true,
        ),
        isNull,
      );
    });

    test('a choice scoped to one Space plays only in that Space', () {
      const choice =
          EntranceSoundChoice(soundId: 'horse', spaceId: '!chosen:x');
      SoundId? pickIn(List<String> spaceIds) => pickEntranceSound(
            choice: choice,
            roomSpaceIds: spaceIds,
            catalog: catalog,
            deafened: false,
          );

      expect(pickIn(['!chosen:x']), 'horse');
      expect(pickIn(['!other:x']), isNull);
      expect(pickIn([]), isNull);
    });

    test('a room in several Spaces plays a choice scoped to any of them', () {
      // A voice room can belong to more than one Space (the soundboard
      // popover lists all of them); "only in Space B" must match a room
      // that is in A and B.
      const choice = EntranceSoundChoice(soundId: 'horse', spaceId: '!b:x');
      expect(
        pickEntranceSound(
          choice: choice,
          roomSpaceIds: const ['!a:x', '!b:x'],
          catalog: catalog,
          deafened: false,
        ),
        'horse',
      );
    });
  });

  group('EntranceSoundGate', () {
    test('fires once per call session, even if the call view is rebuilt', () {
      final gate = EntranceSoundGate();
      final session = Object();

      expect(gate.claim(session, roomId: '!voice:x'), isTrue);
      expect(gate.claim(session, roomId: '!voice:x'), isFalse);
      expect(gate.claim(Object(), roomId: '!voice:x'), isTrue);
    });

    test('"join without sound" skips only the next join of that room', () {
      final gate = EntranceSoundGate();
      gate.skipNextJoin('!voice:x');

      expect(gate.claim(Object(), roomId: '!other:x'), isTrue);
      expect(gate.claim(Object(), roomId: '!voice:x'), isFalse);
      expect(gate.claim(Object(), roomId: '!voice:x'), isTrue);
    });

    test('a failed silent join does not silence the next one', () {
      final gate = EntranceSoundGate();
      gate.skipNextJoin('!voice:x');
      gate.cancelSkip('!voice:x');

      expect(gate.claim(Object(), roomId: '!voice:x'), isTrue);
    });

    test('a silent join request is taken once, by its own room', () {
      final gate = EntranceSoundGate();
      gate.requestSilentJoin('!voice:x');

      expect(gate.takeSilentJoinRequest('!other:x'), isFalse);
      expect(gate.takeSilentJoinRequest('!voice:x'), isTrue);
      expect(gate.takeSilentJoinRequest('!voice:x'), isFalse);
    });

    test('an old silent join request no longer joins the call', () {
      var now = DateTime(2026, 1, 1);
      final gate = EntranceSoundGate(now: () => now);
      gate.requestSilentJoin('!voice:x');

      now = now.add(const Duration(minutes: 1));

      expect(gate.takeSilentJoinRequest('!voice:x'), isFalse);
    });
  });
}
