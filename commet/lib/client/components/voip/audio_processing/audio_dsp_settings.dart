import 'package:commet/main.dart';

/// User facing settings for the voice DSP (rust/audio_dsp), read from
/// preferences. Mirrors `audio_dsp::Params`; the constants below are the
/// tunables we do not expose in the UI.
class AudioDspSettings {
  /// Gain while the input gate is closed. Not a hard mute so room tone stays
  /// natural.
  static const double gateFloorDb = -40;

  /// Extra attenuation while the far end is loud and we are silent.
  static const double duckDepthDb = -20;

  /// Far-end level above which ducking engages.
  static const double duckFarThresholdDb = -45;

  static const int gateModeOff = 0;
  static const int gateModeManual = 1;
  static const int gateModeAuto = 2;

  final bool noiseSuppression;
  final bool gateAuto;
  final double gateThresholdDb;
  final bool farEndDucking;

  const AudioDspSettings({
    required this.noiseSuppression,
    required this.gateAuto,
    required this.gateThresholdDb,
    required this.farEndDucking,
  });

  factory AudioDspSettings.fromPreferences() => AudioDspSettings(
        noiseSuppression: preferences.voipNoiseSuppression.value,
        gateAuto: preferences.voipInputSensitivityAuto.value,
        gateThresholdDb: preferences.voipInputSensitivityDb.value,
        farEndDucking: preferences.voipFarEndDucking.value,
      );

  int get gateMode => gateAuto ? gateModeAuto : gateModeManual;

  /// Shape shared by the AudioWorklet (JS) and the native FFI struct writer.
  Map<String, Object> toMap() => {
        "noiseSuppression": noiseSuppression,
        "gateMode": gateMode,
        "farEndDucking": farEndDucking,
        "gateThresholdDb": gateThresholdDb,
        "gateFloorDb": gateFloorDb,
        "duckDepthDb": duckDepthDb,
        "duckFarThresholdDb": duckFarThresholdDb,
      };

  @override
  bool operator ==(Object other) =>
      other is AudioDspSettings &&
      other.noiseSuppression == noiseSuppression &&
      other.gateAuto == gateAuto &&
      other.gateThresholdDb == gateThresholdDb &&
      other.farEndDucking == farEndDucking;

  @override
  int get hashCode =>
      Object.hash(noiseSuppression, gateAuto, gateThresholdDb, farEndDucking);
}

/// Snapshot of what the DSP is doing, polled about ten times a second while a
/// call is active. Mirrors `audio_dsp::Report`.
class AudioDspReport {
  static const int flagGateOpen = 1 << 0;
  static const int flagNsActive = 1 << 1;
  static const int flagUnsupportedRate = 1 << 2;
  static const int flagDucking = 1 << 3;

  /// Microphone level after noise suppression, before the gate, in dBFS.
  final double levelDb;

  /// Speech probability from RNNoise, 0..1 (0 when suppression is off).
  final double vad;

  /// Level of the other participants' audio, dBFS, with a short peak hold.
  final double farLevelDb;

  /// Gain the gate and ducker are currently applying, dB.
  final double gainDb;

  final int sampleRate;
  final int frames;
  final int flags;

  const AudioDspReport({
    required this.levelDb,
    required this.vad,
    required this.farLevelDb,
    required this.gainDb,
    required this.sampleRate,
    required this.frames,
    required this.flags,
  });

  bool get gateOpen => flags & flagGateOpen != 0;
  bool get noiseSuppressionActive => flags & flagNsActive != 0;
  bool get unsupportedRate => flags & flagUnsupportedRate != 0;
  bool get ducking => flags & flagDucking != 0;

  @override
  String toString() =>
      "AudioDspReport(level: ${levelDb.toStringAsFixed(1)} dBFS, vad: ${vad.toStringAsFixed(2)}, far: ${farLevelDb.toStringAsFixed(1)}, gain: ${gainDb.toStringAsFixed(1)} dB, rate: $sampleRate, frames: $frames, flags: $flags)";
}
