// Loudness normalization for short SFX. Pure Dart.
//
// Algorithm (documented choice):
// - Target: peak -1.0 dBFS (linear 0.891, leaves headroom, avoids
//   inter-sample clipping) + RMS guard at ~-14 dBFS (linear 0.2) so a quiet
//   clip gets lifted but a loud clip is never pushed into clipping.
// - gain = min(targetPeak / peak, targetRms / rms), clamped to [0.25, 4.0].
//   Silent input (peak == 0) yields 1.0 (no-op) rather than +inf.
// - Why not "everything to 0 dBFS": that maximizes surprise/loudness wars
//   and clips on cheap DACs. Peak -1dB + RMS guard keeps SFX consistent
//   without startling users.
// - Runs ONCE at import; playback multiplies pcm * normalizedGain *
//   userVolume (two separate stages, per spec).
//
// Input is mono-mix PCM float64 in [-1, 1]. Callers decode WAV via
// [decodeWav16]; MP3/OGG without a decoder fall back to gain 1.0 with
// [LoudnessEstimate.unmeasured] so we never fake a measurement.
import 'dart:math' as math;
import 'dart:typed_data';

class LoudnessEstimate {
  /// Linear gain to apply at playback.
  final double gain;

  /// Peak of the analyzed signal (0..1+).
  final double peak;

  /// RMS of the analyzed signal.
  final double rms;

  /// True when actually measured from PCM; false = fallback gain 1.0.
  final bool measured;

  const LoudnessEstimate({
    required this.gain,
    required this.peak,
    required this.rms,
    required this.measured,
  });
}

class SoundboardNormalizer {
  static const double targetPeak = 0.891250938; // -1 dBFS
  static const double targetRms = 0.199526231; // ~-14 dBFS
  static const double maxGain = 4.0;
  static const double minGain = 0.25;

  /// Computes gain from PCM samples. Empty/silent -> gain 1.0.
  static LoudnessEstimate analyze(List<double> pcm) {
    if (pcm.isEmpty) {
      return const LoudnessEstimate(
          gain: 1.0, peak: 0.0, rms: 0.0, measured: true);
    }
    var peak = 0.0;
    var sumSq = 0.0;
    for (final s in pcm) {
      final a = s.abs();
      if (a > peak) peak = a;
      sumSq += s * s;
    }
    final rms = math.sqrt(sumSq / pcm.length);
    if (peak <= 1e-9) {
      return LoudnessEstimate(
          gain: 1.0, peak: peak, rms: rms, measured: true);
    }
    var gain = targetPeak / peak;
    if (rms > 1e-9) {
      gain = math.min(gain, targetRms / rms);
    }
    gain = gain.clamp(minGain, maxGain);
    // Never allow a boost that would push the measured peak over 0dBFS.
    if (peak * gain > 1.0) gain = 1.0 / peak;
    return LoudnessEstimate(
        gain: gain, peak: peak, rms: rms, measured: true);
  }

  /// Fallback for encoded formats we cannot decode in pure Dart.
  /// Explicitly marked unmeasured so callers/UI never claim normalization
  /// happened.
  static LoudnessEstimate fallback() => const LoudnessEstimate(
      gain: 1.0, peak: 0.0, rms: 0.0, measured: false);

  /// Minimal WAV (PCM16, PCM24, PCM32-float, mono/stereo) decoder to mono
  /// mix float64. Returns null for unsupported layouts (caller uses fallback).
  /// Supports the WAVs typically exported for SFX; MP3/OGG handled by caller.
  static List<double>? decodeWav16(Uint8List bytes) {
    try {
      if (bytes.length < 44) return null;
      String str(int o, int l) =>
          String.fromCharCodes(bytes.sublist(o, o + l));
      if (str(0, 4) != 'RIFF' || str(8, 4) != 'WAVE') return null;
      var offset = 12;
      var audioFormat = 1;
      var channels = 1;
      var bitsPerSample = 16;
      var dataStart = -1;
      var dataLen = 0;
      while (offset + 8 <= bytes.length) {
        final id = str(offset, 4);
        final size = ByteData.sublistView(bytes, offset + 4, offset + 8)
            .getUint32(0, Endian.little);
        if (id == 'fmt ') {
          final bd =
              ByteData.sublistView(bytes, offset + 8, offset + 8 + size);
          audioFormat = bd.getUint16(0, Endian.little);
          channels = bd.getUint16(2, Endian.little);
          bitsPerSample = bd.getUint16(14, Endian.little);
        } else if (id == 'data') {
          dataStart = offset + 8;
          dataLen = size;
          break;
        }
        offset += 8 + size + (size.isOdd ? 1 : 0);
      }
      if (dataStart < 0) return null;
      if (audioFormat != 1 && audioFormat != 3) return null;
      if (channels < 1 || channels > 8) return null;
      final bd = ByteData.sublistView(bytes);
      final frames = <double>[];
      final bytesPerSample = (bitsPerSample / 8).round();
      final frameSize = bytesPerSample * channels;
      final end = (dataStart + dataLen).clamp(0, bytes.length);
      for (var f = dataStart; f + frameSize <= end; f += frameSize) {
        var mix = 0.0;
        for (var c = 0; c < channels; c++) {
          final o = f + c * bytesPerSample;
          double s;
          if (audioFormat == 3 && bitsPerSample == 32) {
            s = bd.getFloat32(o, Endian.little).clamp(-1.0, 1.0);
          } else if (bitsPerSample == 16) {
            s = bd.getInt16(o, Endian.little) / 32768.0;
          } else if (bitsPerSample == 8) {
            s = (bd.getUint8(o) - 128) / 128.0;
          } else if (bitsPerSample == 24) {
            var v = bd.getUint8(o) |
                (bd.getUint8(o + 1) << 8) |
                (bd.getUint8(o + 2) << 16);
            if ((v & 0x800000) != 0) v |= ~0xFFFFFF;
            s = (v / 8388608.0).clamp(-1.0, 1.0);
          } else {
            return null;
          }
          mix += s;
        }
        frames.add(mix / channels);
      }
      return frames;
    } catch (_) {
      return null;
    }
  }
}
