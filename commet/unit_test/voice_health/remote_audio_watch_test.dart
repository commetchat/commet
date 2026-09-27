// The remote audio watch: someone we are meant to hear whose track never
// arrived, or whose microphone delivers nothing while the server hears
// them speak, is subscribed to again, spaced out, and never for a muted,
// quiet or unwanted track.
import 'package:commet/client/components/voip/remote_audio_watch.dart';
import 'package:flutter_test/flutter_test.dart';

class _Room {
  DateTime now = DateTime(2026, 9, 26, 12);
  late final watch = RemoteAudioWatch(now: () => now);

  bool wanted = true;
  bool hasTrack = true;
  bool muted = false;
  bool speaking = false;
  bool packetsFlow = true;
  bool microphone = true;
  int packets = 0;

  final List<RemoteAudioFault> repairs = [];

  Future<void> run(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      if (hasTrack && packetsFlow && !muted) packets += speaking ? 50 : 2;
      final result = watch.check([
        RemoteAudioVitals(
          id: 'TR_alice',
          wanted: wanted,
          hasTrack: hasTrack,
          muted: muted,
          speaking: speaking,
          packetsReceived: hasTrack ? packets : null,
          isMicrophone: microphone,
        ),
      ]);
      repairs.addAll(result.values);
    }
  }
}

void main() {
  test('someone we hear is left alone, speaking or quiet', () async {
    final room = _Room();
    for (var i = 0; i < 30; i++) {
      room.speaking = i.isEven;
      await room.run(5);
    }
    expect(room.repairs, isEmpty);
  });

  test('a track that never arrives is asked for again', () async {
    final room = _Room()..hasTrack = false;
    await room.run(5);
    expect(room.repairs, isEmpty);
    await room.run(2);
    expect(room.repairs, [RemoteAudioFault.neverArrived]);
  });

  test('someone speaking whom we receive nothing from is resubscribed',
      () async {
    final room = _Room();
    await room.run(10);
    room.speaking = true;
    room.packetsFlow = false;
    await room.run(2);
    expect(room.repairs, isEmpty);
    await room.run(2);
    expect(room.repairs, [RemoteAudioFault.silent]);
  });

  test('the resubscription that brings them back ends the attempts', () async {
    final room = _Room();
    await room.run(10);
    room.speaking = true;
    room.packetsFlow = false;
    await room.run(4);
    expect(room.repairs, hasLength(1));
    room.packetsFlow = true;
    await room.run(60);
    expect(room.repairs, hasLength(1));
    expect(room.watch.attemptsFor('TR_alice'), 0);
  });

  test('attempts go on while it does not help, spaced out', () async {
    final room = _Room();
    await room.run(10);
    room.speaking = true;
    room.packetsFlow = false;
    await room.run(600);
    expect(room.repairs.length, greaterThan(5),
        reason: 'someone we cannot hear is never given up on');
    expect(room.repairs.length, lessThan(20), reason: 'spaced out');
  });

  test('a muted microphone sends nothing, and that is fine', () async {
    final room = _Room();
    await room.run(10);
    room.muted = true;
    room.speaking = true; // their screen audio or the DJ's music
    await room.run(60);
    expect(room.repairs, isEmpty);
  });

  test('quiet with no packets is not a fault: nobody said they spoke',
      () async {
    final room = _Room();
    await room.run(10);
    room.packetsFlow = false;
    await room.run(60);
    expect(room.repairs, isEmpty);
  });

  test('speaking is only a reason for packets on a microphone', () async {
    final room = _Room()..microphone = false;
    await room.run(10);
    room.speaking = true;
    room.packetsFlow = false;
    await room.run(60);
    expect(room.repairs, isEmpty);
  });

  test('a track we do not want is never asked for', () async {
    final room = _Room()
      ..wanted = false
      ..hasTrack = false;
    await room.run(60);
    expect(room.repairs, isEmpty);
  });

  test('a track that goes away is forgotten', () async {
    final room = _Room();
    await room.run(10);
    room.speaking = true;
    room.packetsFlow = false;
    await room.run(4);
    room.watch.check(const []);
    expect(room.watch.attemptsFor('TR_alice'), 0);
  });
}
