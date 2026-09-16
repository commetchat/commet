import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('SoundboardNormalizer', () {
    test('loud clip is turned down without clipping', () {
      final pcm = List<double>.filled(48000, 0.99);
      final est = SoundboardNormalizer.analyze(pcm);
      expect(est.measured, isTrue);
      expect(est.peak * est.gain, lessThanOrEqualTo(1.0));
      expect(est.gain, lessThan(1.0));
    });

    test('quiet clip is lifted but bounded', () {
      final pcm = List<double>.filled(48000, 0.05);
      final est = SoundboardNormalizer.analyze(pcm);
      expect(est.gain, greaterThan(1.0));
      expect(est.gain, lessThanOrEqualTo(SoundboardNormalizer.maxGain));
      expect(est.peak * est.gain, lessThanOrEqualTo(1.0));
    });

    test('two clips with different amplitudes converge', () {
      final loud = SoundboardNormalizer.analyze(List<double>.filled(1000, 0.9));
      final quiet =
          SoundboardNormalizer.analyze(List<double>.filled(1000, 0.1));
      final loudOut = 0.9 * loud.gain;
      final quietOut = 0.1 * quiet.gain;
      // Perceived levels much closer after normalization than before (9x).
      expect((loudOut - quietOut).abs() / loudOut, lessThan(0.6));
    });

    test('silence yields safe no-op gain', () {
      final est = SoundboardNormalizer.analyze(List<double>.filled(100, 0.0));
      expect(est.gain, 1.0);
    });

    test('fallback is explicitly unmeasured', () {
      final est = SoundboardNormalizer.fallback();
      expect(est.measured, isFalse);
      expect(est.gain, 1.0);
    });

    test('WAV decode round-trips peak correctly', () {
      // Build minimal 16-bit mono WAV: 4 samples.
      final samples = [0, 16384, -16384, 32767];
      final dataLen = samples.length * 2;
      final total = 44 + dataLen;
      final bytes = ByteData(total);
      void str(int o, String s) {
        for (var i = 0; i < s.length; i++) {
          bytes.setUint8(o + i, s.codeUnitAt(i));
        }
      }

      str(0, 'RIFF');
      bytes.setUint32(4, total - 8, Endian.little);
      str(8, 'WAVE');
      str(12, 'fmt ');
      bytes.setUint32(16, 16, Endian.little);
      bytes.setUint16(20, 1, Endian.little);
      bytes.setUint16(22, 1, Endian.little);
      bytes.setUint32(24, 48000, Endian.little);
      bytes.setUint32(28, 48000 * 2, Endian.little);
      bytes.setUint16(32, 2, Endian.little);
      bytes.setUint16(34, 16, Endian.little);
      str(36, 'data');
      bytes.setUint32(40, dataLen, Endian.little);
      for (var i = 0; i < samples.length; i++) {
        bytes.setInt16(44 + i * 2, samples[i], Endian.little);
      }
      final pcm = SoundboardNormalizer.decodeWav16(bytes.buffer.asUint8List());
      expect(pcm, isNotNull);
      expect(pcm!.length, 4);
      expect(pcm[3], closeTo(0.9999, 0.001));
      final est = SoundboardNormalizer.analyze(pcm);
      expect(est.peak * est.gain, lessThanOrEqualTo(1.0));
    });
  });
}
