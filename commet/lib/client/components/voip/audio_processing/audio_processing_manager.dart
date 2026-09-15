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
    if (_reports.hasListener) {
      _reports.add(report);
    }
  }

  void dispose() {
    _settingsSubscription?.cancel();
    _reports.close();
  }
}
