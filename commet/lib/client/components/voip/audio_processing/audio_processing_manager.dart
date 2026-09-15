import 'dart:async';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/main.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'audio_processing_manager_stub.dart'
    if (dart.library.io) 'audio_processing_manager_native.dart'
    if (dart.library.js_interop) 'audio_processing_manager_web.dart';

/// Owns the voice DSP (noise suppression, input gate, far-end ducking) for
/// the lifetime of the app and attaches it to calls.
///
/// Native (Linux, Windows): the DSP is installed on WebRTC's audio processing
/// module through the vendored LiveKit plugin, so it covers every local
/// microphone track, including legacy 1:1 calls.
///
/// Web: the DSP runs in an AudioWorklet between `getUserMedia` and the
/// published track, delivered as a LiveKit [lk.TrackProcessor].
///
/// Android and others: unsupported for now, everything is a no-op.
///
/// See docs/voice-audio-processing.md.
abstract class AudioProcessingManager {
  static AudioProcessingManager? _instance;

  static AudioProcessingManager get instance =>
      _instance ??= createAudioProcessingManager();

  StreamSubscription? _settingsSubscription;
  AudioDspSettings _lastSettings = AudioDspSettings.fromPreferences();

  final StreamController<AudioDspReport> _reports =
      StreamController.broadcast();

  AudioProcessingManager() {
    _settingsSubscription = preferences.onSettingChanged.listen((_) {
      final settings = AudioDspSettings.fromPreferences();
      if (settings == _lastSettings) return;
      _lastSettings = settings;
      applySettings(settings);
    });
  }

  /// Whether this platform can run the DSP at all.
  bool get isSupported;

  /// Whether the DSP is currently attached to a call.
  bool get isActive;

  /// Level and gate state, about ten times a second while [isActive].
  Stream<AudioDspReport> get onReport => _reports.stream;

  // Reports keep coming while the frame counter is stuck if the hook stops
  // receiving audio, so liveness is judged by the counter.
  static const Duration _liveWindow = Duration(milliseconds: 500);
  int _lastFrames = -1;
  DateTime? _framesAdvancedAt;
  DateTime? _gateOpenAt;

  /// Whether the DSP is processing microphone audio right now, which makes
  /// its gate the judge of what actually leaves the client.
  bool get isProcessing {
    final t = _framesAdvancedAt;
    return isActive &&
        t != null &&
        DateTime.now().difference(t) < _liveWindow;
  }

  /// Last time the input gate was seen open, i.e. the microphone was being
  /// sent at full gain. The gate holds for 150 ms and reports come every
  /// 100 ms, so no opening is missed.
  DateTime? get lastGateOpenAt => _gateOpenAt;

  AudioDspSettings get settings => _lastSettings;

  /// Called by [CallManager] for every session that starts.
  Future<void> onSessionStarted(VoipSession session);

  /// Called by [CallManager] once no sessions remain.
  Future<void> onSessionEnded();

  /// Web only: a processor to hand to `AudioCaptureOptions`. Null elsewhere.
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor();

  /// Push new tunables into a running DSP.
  Future<void> applySettings(AudioDspSettings settings);

  void publishReport(AudioDspReport report) {
    if (report.frames != _lastFrames) {
      _lastFrames = report.frames;
      final now = DateTime.now();
      _framesAdvancedAt = now;
      if (report.gateOpen) _gateOpenAt = now;
    }

    if (_reports.hasListener) {
      _reports.add(report);
    }
  }

  void dispose() {
    _settingsSubscription?.cancel();
    _reports.close();
  }
}
