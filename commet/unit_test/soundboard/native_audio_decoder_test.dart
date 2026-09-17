@TestOn('linux')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:commet/client/components/soundboard/audio_decoder/audio_decoder_native.dart';
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:test/test.dart';

// Runs against rust/audio_decode when it has been built
// (`cargo build -p audio_decode`, which CI does before the Dart tests).
const _lib = '../target/debug/libaudio_decode.so';
const _fixtures = '../rust/audio_decode/tests/fixtures';

void main() {
  final skip = File(_lib).existsSync()
      ? false
      : 'run `cargo build -p audio_decode` first';

  test('an MP3 decoded by Rust measures like ffmpeg does', () {
    final decoder = NativeAudioDecoder.open(DynamicLibrary.open(_lib))!;
    final bytes = File('$_fixtures/sine_-20dbfs_stereo.mp3').readAsBytesSync();
    final pcm = decoder.decode(bytes, 'audio/mpeg')!;
    expect(pcm.sampleRate, 44100);
    expect(pcm.channels, hasLength(2));
    final est = SoundboardNormalizer.analyze(pcm);
    // ffmpeg -af ebur128=peak=true: I -20.4 LUFS, true peak -20.4 dBTP.
    expect(est.measured, isTrue);
    expect(est.integratedLufs, closeTo(-20.4, 0.3));
    expect(est.truePeakDbtp, closeTo(-20.4, 0.5));
    expect(est.integratedLufs! + est.gainDb,
        closeTo(SoundboardNormalizer.targetLufs, 1));
  }, skip: skip);

  // The issue's acceptance levels, as MP3. References from
  // `ffmpeg -af ebur128=peak=true:dualmono=true`.
  for (final (file, lufs, peak) in [
    ('noise_-30lufs.mp3', -30.6, -21.4),
    ('noise_-6lufs.mp3', -6.6, 0.7),
  ]) {
    test('$file lands within 1 LU of the target', () {
      final decoder = NativeAudioDecoder.open(DynamicLibrary.open(_lib))!;
      final bytes = File('$_fixtures/$file').readAsBytesSync();
      final est =
          SoundboardNormalizer.analyze(decoder.decode(bytes, 'audio/mpeg')!);
      expect(est.integratedLufs, closeTo(lufs, 0.3));
      expect(est.truePeakDbtp, closeTo(peak, 0.5));
      expect(lufs + est.gainDb, closeTo(SoundboardNormalizer.targetLufs, 1));
    }, skip: skip);
  }

  test('Ogg Vorbis decodes too', () {
    final decoder = NativeAudioDecoder.open(DynamicLibrary.open(_lib))!;
    final bytes = File('$_fixtures/sine_-20dbfs_mono.ogg').readAsBytesSync();
    final est =
        SoundboardNormalizer.analyze(decoder.decode(bytes, 'audio/ogg')!);
    // ffmpeg -af ebur128=dualmono=true: I -19.9 LUFS.
    expect(est.integratedLufs, closeTo(-19.9, 0.3));
  }, skip: skip);

  test('garbage is not decodable', () {
    final decoder = NativeAudioDecoder.open(DynamicLibrary.open(_lib))!;
    expect(
        decoder.decode(
            File(_lib).readAsBytesSync().sublist(0, 4096), 'audio/mpeg'),
        isNull);
  }, skip: skip);
}
