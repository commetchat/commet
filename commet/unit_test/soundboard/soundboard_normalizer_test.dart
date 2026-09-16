import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:test/test.dart';

Float32List sine(double amplitude, double seconds,
    {int rate = 48000, double hz = 997, double phase = 0}) {
  final out = Float32List((seconds * rate).round());
  for (var i = 0; i < out.length; i++) {
    out[i] = amplitude * math.sin(2 * math.pi * hz * i / rate + phase);
  }
  return out;
}

/// A minimal 16-bit PCM WAV with the given header values.
Uint8List _wav16(
    {required int rate, required int channels, required List<int> samples}) {
  final bytes = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * channels * 2, Endian.little);
  bytes.setUint16(32, channels * 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  group('SoundboardNormalizer.analyze', () {
    // Reference: BS.1770-4 / EBU Tech 3341, a 997 Hz sine at A dBFS on both
    // channels reads A LUFS.
    test('stereo 997 Hz sine at -20 dBFS reads -20 LUFS', () {
      final s = sine(0.1, 2);
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.measured, isTrue);
      expect(est.integratedLufs, closeTo(-20, 0.1));
    });

    test('mono reads the same as the identical stereo file (dual mono)', () {
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 44100, channels: [sine(0.1, 2, rate: 44100)]));
      expect(est.integratedLufs, closeTo(-20, 0.1));
    });

    test('silence after the sound is gated out', () {
      // 1 s of -20 dBFS then 5 s of silence. Ungated this would read about
      // -27.8; ffmpeg's ebur128 reads -20.7 (edge blocks pass the gate).
      final s = Float32List(48000 * 6)..setAll(0, sine(0.1, 1));
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.integratedLufs, closeTo(-20.7, 0.1));
    });

    test('a clip shorter than one 400 ms block is still measured', () {
      final s = sine(0.1, 0.1);
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.integratedLufs, closeTo(-20, 0.3));
    });

    // A sine at fs/4 sampled 45 degrees off its peaks: every sample is
    // 0.707 (-3 dBFS) but the waveform reaches 1.0 (0 dBTP).
    test('true peak sees the inter-sample peak', () {
      final s = sine(1.0, 1, hz: 12000, phase: math.pi / 4);
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.truePeakDbtp, closeTo(0, 0.5));
    });

    test('silence is a measured no-op', () {
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [Float32List(48000)]));
      expect(est.measured, isTrue);
      expect(est.integratedLufs, isNull);
      expect(est.gain, 1.0);
    });

    test('a very quiet clip is boosted by at most 18 dB', () {
      final s = sine(0.001, 1); // -60 LUFS
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.gainDb, closeTo(18, 0.01));
    });

    test('a boost never pushes the true peak over -1 dBTP', () {
      // -30 LUFS body with one full-scale click.
      final s = sine(0.0316, 1)..[1000] = 0.5;
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.truePeakDbtp! + est.gainDb, lessThanOrEqualTo(-1 + 1e-9));
      expect(est.gainDb, greaterThan(0));
    });

    test('a peaky clip is held under -1 dBTP even below the target', () {
      // -20 LUFS body with one full-scale sample: reaching -16 LUFS would
      // need +4 dB, the ceiling allows about -1 dB.
      final s = sine(0.1, 1)..[1000] = 1.0;
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.truePeakDbtp! + est.gainDb, closeTo(-1, 1e-6));
    });

    test('a clip above the peak ceiling is still attenuated to the target', () {
      final s = sine(1.0, 1); // 0 LUFS, 0 dBTP
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 48000, channels: [s, s]));
      expect(est.integratedLufs! + est.gainDb, closeTo(-16, 0.01));
    });

    // Fixtures are pink noise levelled with ffmpeg; the reference readings
    // come from `ffmpeg -af ebur128=peak=true:dualmono=true`.
    for (final (file, lufs, peak) in [
      ('noise_-30lufs.wav', -30.0, -20.7),
      ('noise_-6lufs.wav', -6.1, 1.1),
    ]) {
      test('$file matches ffmpeg and lands within 1 LU of the target', () {
        final bytes =
            File('unit_test/soundboard/fixtures/$file').readAsBytesSync();
        final est = SoundboardNormalizer.analyze(
            SoundboardNormalizer.decodeWav(bytes)!);
        expect(est.integratedLufs, closeTo(lufs, 0.3));
        expect(est.truePeakDbtp, closeTo(peak, 0.5));
        expect(lufs + est.gainDb, closeTo(SoundboardNormalizer.targetLufs, 1));
      });
    }
  });

  group('SoundboardNormalizer.decodeWav', () {
    test('decodes 16-bit stereo into channels', () {
      final samples = [0, 16384, -16384, 32767]; // L R L R
      final bytes = ByteData(44 + samples.length * 2);
      void str(int o, String s) {
        for (var i = 0; i < s.length; i++) {
          bytes.setUint8(o + i, s.codeUnitAt(i));
        }
      }

      str(0, 'RIFF');
      bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
      str(8, 'WAVE');
      str(12, 'fmt ');
      bytes.setUint32(16, 16, Endian.little);
      bytes.setUint16(20, 1, Endian.little);
      bytes.setUint16(22, 2, Endian.little);
      bytes.setUint32(24, 8000, Endian.little);
      bytes.setUint32(28, 8000 * 4, Endian.little);
      bytes.setUint16(32, 4, Endian.little);
      bytes.setUint16(34, 16, Endian.little);
      str(36, 'data');
      bytes.setUint32(40, samples.length * 2, Endian.little);
      for (var i = 0; i < samples.length; i++) {
        bytes.setInt16(44 + i * 2, samples[i], Endian.little);
      }
      final pcm = SoundboardNormalizer.decodeWav(bytes.buffer.asUint8List())!;
      expect(pcm.sampleRate, 8000);
      expect(pcm.channels, hasLength(2));
      expect(pcm.channels[0], [0.0, -0.5]);
      expect(pcm.channels[1][0], 0.5);
      expect(pcm.channels[1][1], closeTo(0.99997, 1e-5));
    });

    test('rejects non-WAV bytes', () {
      expect(SoundboardNormalizer.decodeWav(Uint8List(100)), isNull);
    });

    test('a sample rate too low to be audio is not measured', () {
      // Reaches analyze through the Rust decoder too, so it must return
      // promptly instead of looping on a zero hop.
      final est = SoundboardNormalizer.analyze(
          PcmAudio(sampleRate: 4, channels: [Float32List(8)]));
      expect(est.measured, isFalse);
      expect(est.gain, 1.0);
    });

    test('rejects a sample rate too low to be audio', () {
      // A hostile file: with a 4 Hz rate the 100 ms analysis hop rounds to
      // zero and the loudness loop would never advance.
      final bytes = _wav16(rate: 4, channels: 1, samples: [0, 1000, -1000, 0]);
      expect(SoundboardNormalizer.decodeWav(bytes), isNull);
    });
  });

  test('fallback is explicitly unmeasured', () {
    final est = SoundboardNormalizer.fallback();
    expect(est.measured, isFalse);
    expect(est.gain, 1.0);
  });
}
