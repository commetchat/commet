// Loudness normalization for short SFX. Pure Dart.
//
// Algorithm (documented choice):
// - Metric: integrated loudness per ITU-R BS.1770-4 / EBU R128 (K-weighting,
//   400 ms blocks with 75 % overlap, -70 LUFS absolute gate, -10 LU
//   relative gate). Clips shorter than one block are measured as a single
//   block so a 200 ms "bonk" still gets a reading.
// - Mono counts as dual mono: it plays through both speakers, so it must
//   read the same as the identical stereo file.
// - Target -16 LUFS (what Discord-like apps and podcasts use for voice-level
//   content). gain = target - measured, clamped to +/-18 dB.
// - The gain never leaves the true peak (4x oversampled, BS.1770 Annex 2)
//   above -1 dBTP. We store a gain, not processed bytes, so there is no
//   limiter: a clip with a big transient plays under target rather than
//   clipping.
// - Runs ONCE at import; playback multiplies pcm * normalizedGain *
//   userVolume (two separate stages, per spec).
//
// Input is planar float PCM in [-1, 1] ([PcmAudio]). WAV is decoded here
// ([decodeWav]); MP3/Ogg go through `audio_decoder.dart`. When nothing can
// decode the bytes, callers use [SoundboardNormalizer.fallback] so we never
// fake a measurement.
import 'dart:math' as math;
import 'dart:typed_data';

/// Decoded audio, one sample list per channel.
class PcmAudio {
  final int sampleRate;
  final List<Float32List> channels;

  const PcmAudio({required this.sampleRate, required this.channels});

  int get frames => channels.isEmpty ? 0 : channels.first.length;

  int get durationMs =>
      sampleRate <= 0 ? 0 : (frames * 1000 / sampleRate).round();

  /// Splits interleaved samples into channels.
  factory PcmAudio.interleaved(
      Float32List samples, int channelCount, int sampleRate) {
    final frames = samples.length ~/ channelCount;
    final channels = List.generate(channelCount, (_) => Float32List(frames));
    for (var f = 0; f < frames; f++) {
      for (var c = 0; c < channelCount; c++) {
        channels[c][f] = samples[f * channelCount + c];
      }
    }
    return PcmAudio(sampleRate: sampleRate, channels: channels);
  }
}

class LoudnessEstimate {
  /// Linear gain to apply at playback.
  final double gain;

  /// Integrated loudness in LUFS; null when unmeasured or below the
  /// absolute gate (silence).
  final double? integratedLufs;

  /// True peak in dBTP; null when unmeasured or silent.
  final double? truePeakDbtp;

  /// True when actually measured from PCM; false = fallback gain 1.0.
  final bool measured;

  const LoudnessEstimate({
    required this.gain,
    required this.measured,
    this.integratedLufs,
    this.truePeakDbtp,
  });

  double get gainDb => _toDb(gain);

  @override
  String toString() => 'measured=$measured '
      'lufs=${integratedLufs?.toStringAsFixed(1) ?? '-'} '
      'truePeak=${truePeakDbtp?.toStringAsFixed(1) ?? '-'} dBTP '
      'gain=${gain.toStringAsFixed(3)} (${gainDb.toStringAsFixed(1)} dB)';
}

double _toDb(double linear) => 20 * math.log(linear) / math.ln10;
double _fromDb(double db) => math.pow(10, db / 20).toDouble();

class SoundboardNormalizer {
  static const double targetLufs = -16.0;
  static const double maxTruePeakDbtp = -1.0;
  static const double maxGainDb = 18.0;
  static const double absoluteGateLufs = -70.0;
  static const double relativeGateLu = -10.0;

  static double get maxGain => _fromDb(maxGainDb);
  static double get minGain => _fromDb(-maxGainDb);

  static LoudnessEstimate analyze(PcmAudio audio) {
    if (audio.frames == 0 || audio.sampleRate <= 0) {
      return const LoudnessEstimate(gain: 1.0, measured: true);
    }
    final lufs = integratedLoudness(audio);
    final peak = truePeak(audio);
    if (lufs == null || peak <= 0) {
      return const LoudnessEstimate(gain: 1.0, measured: true);
    }
    final peakDb = _toDb(peak);
    var gainDb = (targetLufs - lufs).clamp(-maxGainDb, maxGainDb);
    gainDb = math.min(gainDb, maxTruePeakDbtp - peakDb);
    return LoudnessEstimate(
      gain: _fromDb(gainDb),
      measured: true,
      integratedLufs: lufs,
      truePeakDbtp: peakDb,
    );
  }

  /// Fallback for encoded formats we cannot decode on this platform.
  /// Explicitly marked unmeasured so callers/UI never claim normalization
  /// happened.
  static LoudnessEstimate fallback() =>
      const LoudnessEstimate(gain: 1.0, measured: false);

  /// BS.1770-4 gated loudness, or null when every block is below the
  /// absolute gate.
  static double? integratedLoudness(PcmAudio audio) {
    final rate = audio.sampleRate;
    final weighted = [
      for (final ch in audio.channels) _kWeight(ch, rate),
    ];
    final weights = _channelWeights(audio.channels.length);
    final frames = audio.frames;
    var blockLen = (0.4 * rate).round();
    var hop = (0.1 * rate).round();
    if (frames < blockLen) {
      blockLen = frames;
      hop = frames;
    }
    // Per-block weighted mean square, via prefix sums of z^2 per channel.
    final prefix = [
      for (final ch in weighted) _prefixSquares(ch),
    ];
    final powers = <double>[];
    for (var start = 0; start + blockLen <= frames; start += hop) {
      var power = 0.0;
      for (var c = 0; c < prefix.length; c++) {
        final sum = prefix[c][start + blockLen] - prefix[c][start];
        power += weights[c] * sum / blockLen;
      }
      powers.add(power);
    }
    double loudness(double power) => -0.691 + 10 * math.log(power) / math.ln10;

    final absGated = [
      for (final p in powers)
        if (p > 0 && loudness(p) > absoluteGateLufs) p,
    ];
    if (absGated.isEmpty) return null;
    final relGate = loudness(_mean(absGated)) + relativeGateLu;
    final gated = [
      for (final p in absGated)
        if (loudness(p) > relGate) p,
    ];
    return loudness(_mean(gated.isEmpty ? absGated : gated));
  }

  /// Linear true peak across channels (BS.1770-4 Annex 2 style: 4x
  /// oversampling below 96 kHz, 2x below 192 kHz).
  static double truePeak(PcmAudio audio) {
    final factor = audio.sampleRate < 96000
        ? 4
        : audio.sampleRate < 192000
            ? 2
            : 1;
    var peak = 0.0;
    for (final ch in audio.channels) {
      peak = math.max(peak, _oversampledPeak(ch, factor));
    }
    return peak;
  }

  static List<double> _channelWeights(int count) {
    // 5.1 (L R C LFE Ls Rs): LFE ignored, surrounds +1.5 dB.
    if (count == 6) return const [1, 1, 1, 0, 1.41, 1.41];
    // Mono is dual mono (see header).
    if (count == 1) return const [2];
    return List.filled(count, 1.0);
  }

  static double _mean(List<double> xs) =>
      xs.fold(0.0, (a, b) => a + b) / xs.length;

  static Float64List _prefixSquares(Float64List x) {
    final out = Float64List(x.length + 1);
    for (var i = 0; i < x.length; i++) {
      out[i + 1] = out[i] + x[i] * x[i];
    }
    return out;
  }

  /// Two-stage K-weighting filter (high shelf + RLB high pass), with
  /// coefficients derived for [rate] as in libebur128.
  static Float64List _kWeight(Float32List x, int rate) {
    var f0 = 1681.974450955533;
    const g = 3.999843853973347;
    var q = 0.7071752369554196;
    var k = math.tan(math.pi * f0 / rate);
    final vh = math.pow(10.0, g / 20.0).toDouble();
    final vb = math.pow(vh, 0.4996667741545416).toDouble();
    var a0 = 1.0 + k / q + k * k;
    final pb0 = (vh + vb * k / q + k * k) / a0;
    final pb1 = 2.0 * (k * k - vh) / a0;
    final pb2 = (vh - vb * k / q + k * k) / a0;
    final pa1 = 2.0 * (k * k - 1.0) / a0;
    final pa2 = (1.0 - k / q + k * k) / a0;

    f0 = 38.13547087602444;
    q = 0.5003270373238773;
    k = math.tan(math.pi * f0 / rate);
    a0 = 1.0 + k / q + k * k;
    final ra1 = 2.0 * (k * k - 1.0) / a0;
    final ra2 = (1.0 - k / q + k * k) / a0;

    final out = Float64List(x.length);
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0; // stage 1 state
    var u1 = 0.0, u2 = 0.0; // stage 2 state (input = y)
    var z1 = 0.0, z2 = 0.0;
    for (var i = 0; i < x.length; i++) {
      final xi = x[i].toDouble();
      final y = pb0 * xi + pb1 * x1 + pb2 * x2 - pa1 * y1 - pa2 * y2;
      x2 = x1;
      x1 = xi;
      y2 = y1;
      y1 = y;
      final z = y - 2.0 * u1 + u2 - ra1 * z1 - ra2 * z2;
      u2 = u1;
      u1 = y;
      z2 = z1;
      z1 = z;
      out[i] = z;
    }
    return out;
  }

  static final Map<int, Float64List> _interpTaps = {};

  /// Hann-windowed sinc interpolator (49 taps at 4x), as libebur128 uses.
  static Float64List _taps(int factor) => _interpTaps.putIfAbsent(factor, () {
        final n = 12 * factor + 1;
        final taps = Float64List(n);
        for (var j = 0; j < n; j++) {
          final m = j - (n - 1) / 2;
          final arg = m * math.pi / factor;
          final sinc = m == 0 ? 1.0 : math.sin(arg) / arg;
          final window = 0.5 * (1 - math.cos(2 * math.pi * j / (n - 1)));
          taps[j] = sinc * window;
        }
        return taps;
      });

  static double _oversampledPeak(Float32List x, int factor) {
    var peak = 0.0;
    for (final s in x) {
      if (s.abs() > peak) peak = s.abs();
    }
    if (factor == 1) return peak;
    final taps = _taps(factor);
    final n = taps.length;
    // y(i + p/factor) = sum over k of x[k] * taps[(i - k) * factor + p + half],
    // so tap j lines up with input sample i + (p + half - j) / factor.
    final half = (n - 1) ~/ 2;
    for (var i = 0; i < x.length; i++) {
      for (var p = 1; p < factor; p++) {
        var acc = 0.0;
        for (var j = (half + p) % factor; j < n; j += factor) {
          final idx = i + (p + half - j) ~/ factor;
          if (idx < 0 || idx >= x.length) continue;
          acc += x[idx] * taps[j];
        }
        if (acc.abs() > peak) peak = acc.abs();
      }
    }
    return peak;
  }

  /// Minimal WAV decoder (PCM 8/16/24-bit, 32-bit float, 1..8 channels).
  /// Returns null for anything else (caller tries other decoders).
  static PcmAudio? decodeWav(Uint8List bytes) {
    try {
      if (bytes.length < 44) return null;
      String str(int o, int l) => String.fromCharCodes(bytes.sublist(o, o + l));
      if (str(0, 4) != 'RIFF' || str(8, 4) != 'WAVE') return null;
      var offset = 12;
      var audioFormat = 1;
      var channels = 1;
      var sampleRate = 0;
      var bitsPerSample = 16;
      var dataStart = -1;
      var dataLen = 0;
      while (offset + 8 <= bytes.length) {
        final id = str(offset, 4);
        final size = ByteData.sublistView(bytes, offset + 4, offset + 8)
            .getUint32(0, Endian.little);
        if (id == 'fmt ') {
          final bd = ByteData.sublistView(bytes, offset + 8, offset + 8 + size);
          audioFormat = bd.getUint16(0, Endian.little);
          channels = bd.getUint16(2, Endian.little);
          sampleRate = bd.getUint32(4, Endian.little);
          bitsPerSample = bd.getUint16(14, Endian.little);
          // WAVE_FORMAT_EXTENSIBLE: the real format is the subformat GUID's
          // first two bytes.
          if (audioFormat == 0xFFFE && size >= 26) {
            audioFormat = bd.getUint16(24, Endian.little);
          }
        } else if (id == 'data') {
          dataStart = offset + 8;
          dataLen = size;
          break;
        }
        offset += 8 + size + (size.isOdd ? 1 : 0);
      }
      if (dataStart < 0 || sampleRate <= 0) return null;
      if (audioFormat != 1 && audioFormat != 3) return null;
      if (channels < 1 || channels > 8) return null;
      if (audioFormat == 3 && bitsPerSample != 32) return null;
      if (audioFormat == 1 && ![8, 16, 24].contains(bitsPerSample)) {
        return null;
      }
      final bd = ByteData.sublistView(bytes);
      final bytesPerSample = bitsPerSample ~/ 8;
      final frameSize = bytesPerSample * channels;
      final end = math.min(dataStart + dataLen, bytes.length);
      final frames = (end - dataStart) ~/ frameSize;
      final out = List.generate(channels, (_) => Float32List(frames));
      for (var f = 0; f < frames; f++) {
        for (var c = 0; c < channels; c++) {
          final o = dataStart + f * frameSize + c * bytesPerSample;
          double s;
          if (audioFormat == 3) {
            s = bd.getFloat32(o, Endian.little);
          } else if (bitsPerSample == 16) {
            s = bd.getInt16(o, Endian.little) / 32768.0;
          } else if (bitsPerSample == 8) {
            s = (bd.getUint8(o) - 128) / 128.0;
          } else {
            var v = bd.getUint8(o) |
                (bd.getUint8(o + 1) << 8) |
                (bd.getUint8(o + 2) << 16);
            if ((v & 0x800000) != 0) v |= ~0xFFFFFF;
            s = v / 8388608.0;
          }
          out[c][f] = s;
        }
      }
      return PcmAudio(sampleRate: sampleRate, channels: out);
    } catch (_) {
      return null;
    }
  }
}
