import 'dart:async';
import 'dart:math' as math;

import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:test/test.dart';

// mpv's software volume multiplies samples by (volume / 100)^3.
double mpvAmplitude(double volume) => math.pow(volume / 100, 3).toDouble();

class FakeAudioInstance implements SoundboardAudioInstance {
  final _finished = StreamController<void>.broadcast();
  String? openedUri;
  double? volume;
  bool disposed = false;

  void finish() => _finished.add(null);

  @override
  Stream<void> get finished => _finished.stream;

  @override
  Future<void> open(String uri) async => openedUri = uri;

  @override
  Future<void> setVolume(double mpvVolume) async => volume = mpvVolume;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _finished.close();
  }
}

SoundboardSound sound(String id, {double gain = 1.0}) => SoundboardSound(
      soundId: id,
      name: id,
      emoji: const SoundboardEmoji.unicode('📯'),
      mediaUri: 'mxc://x/$id',
      mimeType: 'audio/mpeg',
      durationMs: 1000,
      normalizedGain: gain,
    );

void main() {
  late List<FakeAudioInstance> instances;
  late List<String> finished;
  late MediaKitSoundboardPlayer player;

  setUp(() {
    instances = [];
    finished = [];
    player = MediaKitSoundboardPlayer(
      resolveSound: (id) => id == 'gone' ? null : sound(id, gain: 0.5),
      resolvePlayableUri: (s) async => 'file:///cache/${s.soundId}.mp3',
      createInstance: () {
        final i = FakeAudioInstance();
        instances.add(i);
        return i;
      },
      onInstanceFinished: finished.add,
    );
  });

  test('the same sound started twice plays in two separate instances',
      () async {
    await player.start('e1', 'horse');
    await player.start('e2', 'horse');
    expect(instances, hasLength(2));
    expect(instances.map((i) => i.openedUri),
        everyElement('file:///cache/horse.mp3'));
    expect(instances.any((i) => i.disposed), isFalse);
    expect(player.isPlaying('e1'), isTrue);
    expect(player.isPlaying('e2'), isTrue);
  });

  test('an instance that ends is disposed and reported, others keep playing',
      () async {
    await player.start('e1', 'horse');
    await player.start('e2', 'horse');
    instances[0].finish();
    await pumpEventQueue();
    expect(instances[0].disposed, isTrue);
    expect(instances[1].disposed, isFalse);
    expect(finished, ['e1']);
    expect(player.isPlaying('e1'), isFalse);
    expect(player.isPlaying('e2'), isTrue);
  });

  test('stopAll disposes every instance', () async {
    await player.start('e1', 'horse');
    await player.start('e2', 'horse');
    await player.stopAll();
    expect(instances.map((i) => i.disposed), [true, true]);
    expect(player.isPlaying('e1'), isFalse);
  });

  test('an unknown sound opens nothing and is reported finished', () async {
    await player.start('e1', 'gone');
    expect(instances, isEmpty);
    expect(finished, ['e1']);
  });

  test('a failed uri resolution disposes the instance and reports it',
      () async {
    final failing = MediaKitSoundboardPlayer(
      resolveSound: (id) => sound(id),
      resolvePlayableUri: (s) async => throw StateError('no cache'),
      createInstance: () {
        final i = FakeAudioInstance();
        instances.add(i);
        return i;
      },
      onInstanceFinished: finished.add,
    );
    await failing.start('e1', 'horse');
    expect(instances.single.disposed, isTrue);
    expect(finished, ['e1']);
    expect(failing.isPlaying('e1'), isFalse);
  });

  test('an instance that never reports an end is released after its lifetime',
      () async {
    final stalling = MediaKitSoundboardPlayer(
      resolveSound: (id) => sound(id),
      resolvePlayableUri: (s) async => 'file:///cache/${s.soundId}.mp3',
      createInstance: () {
        final i = FakeAudioInstance();
        instances.add(i);
        return i;
      },
      onInstanceFinished: finished.add,
      maxInstanceLifetime: const Duration(milliseconds: 20),
    );
    await stalling.start('e1', 'horse');
    expect(finished, isEmpty);
    await Future.delayed(const Duration(milliseconds: 60));
    expect(instances.single.disposed, isTrue);
    expect(finished, ['e1']);
  });

  test('volume applies per instance with the sound\'s normalized gain',
      () async {
    await player.setVolumeFor('e1', 0.8);
    await player.start('e1', 'horse');
    expect(mpvAmplitude(instances.single.volume!), closeTo(0.4, 1e-9));
    await player.setVolumeFor('e1', 1.0);
    expect(mpvAmplitude(instances.single.volume!), closeTo(0.5, 1e-9));
  });

  test('player volume is on media_kit\'s 0..100 scale', () {
    // 0.8 here once meant mpv volume 0.8 of 100: inaudible.
    expect(MediaKitSoundboardPlayer.mpvVolume(1.0, 1.0), closeTo(100, 1e-9));
    expect(MediaKitSoundboardPlayer.mpvVolume(0, 1.0), 0);
  });

  test('mpv plays the linear product of user volume and gain', () {
    for (final (user, gain) in [(0.8, 1.0), (1.0, 0.5), (0.5, 0.25)]) {
      expect(mpvAmplitude(MediaKitSoundboardPlayer.mpvVolume(user, gain)),
          closeTo(user * gain, 1e-9));
    }
  });

  test('a normalization boost is applied', () {
    expect(mpvAmplitude(MediaKitSoundboardPlayer.mpvVolume(1.0, 4.0)),
        closeTo(4.0, 1e-9));
  });

  test('the loudest allowed setting fits under mpv\'s volume-max', () {
    final loudest =
        MediaKitSoundboardPlayer.mpvVolume(1.5, SoundboardNormalizer.maxGain);
    expect(loudest, lessThanOrEqualTo(MediaKitSoundboardPlayer.mpvVolumeMax));
    expect(mpvAmplitude(loudest),
        closeTo(1.5 * SoundboardNormalizer.maxGain, 1e-9));
  });

  test('admin volume scales one sound on top of normalization', () {
    const quiet = SoundboardSound(
      soundId: 's1',
      name: 'Airhorn',
      emoji: SoundboardEmoji.unicode('📢'),
      mediaUri: 'mxc://x/s1',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 0.8,
      volume: 0.5,
    );
    // normalizedGain * adminVolume * userVolume = 0.8 * 0.5 * 1.0
    expect(mpvAmplitude(MediaKitSoundboardPlayer.mpvVolume(1.0, quiet.gain)),
        closeTo(0.4, 1e-9));
  });
}
