import 'dart:async';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
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
/// Outside a call the settings page can run a microphone test
/// ([startMicTest]): the microphone is captured through the same DSP so the
/// level meter works, optionally played back so the user can hear what noise
/// suppression does. Joining a call stops the test.
///
/// See docs/voice-audio-processing.md.
abstract class AudioProcessingManager {
  static AudioProcessingManager? _instance;

  static AudioProcessingManager get instance =>
      _instance ??= createAudioProcessingManager();

  /// Replaces [instance], for tests.
  @visibleForTesting
  static set debugInstance(AudioProcessingManager? manager) =>
      _instance = manager;

  StreamSubscription? _settingsSubscription;
  AudioDspSettings _lastSettings = AudioDspSettings.fromPreferences();

  final StreamController<AudioDspReport> _reports =
      StreamController.broadcast();

  final StreamController<void> _stateChanged = StreamController.broadcast();

  AudioProcessingManager() {
    _settingsSubscription = preferences.onSettingChanged.listen((_) {
      final settings = AudioDspSettings.fromPreferences();
      if (settings == _lastSettings) return;
      final previous = _lastSettings;
      _lastSettings = settings;
      applySettings(settings);
      if (previous.noiseSuppression != settings.noiseSuppression) {
        onNoiseSuppressionChanged(settings.noiseSuppression);
      }
    });
  }

  /// Whether the DSP can run here. On the web this is only exact once
  /// [ensureReady] has completed.
  bool get isSupported;

  /// Finds out whether the DSP can run, where that takes a moment: the web
  /// fetches and test-runs audio_dsp.wasm. A call awaits this before it
  /// decides who suppresses noise, so a DSP that cannot run is known before
  /// WebRTC's (the browser's) suppressor is turned off for it.
  Future<bool> ensureReady() async => isSupported;

  /// Why the DSP cannot run on a platform that is meant to have it (the
  /// library or the wasm is missing or broken), for the user to see. Null
  /// when it runs, and where it simply does not exist yet (Android).
  String? get unavailableReason => null;

  /// Whether the DSP is currently attached to a call or a microphone test.
  bool get isActive;

  /// The calls using the DSP, as CallManager reported them, compared with
  /// `==` like CallManager does. Kept here rather than trusting whoever
  /// reports an end to know it was the last call: after an app refresh the
  /// old CallManager still sees its own call end, late, and used to take the
  /// DSP off the call the user had rejoined in the meantime.
  final List<VoipSession> _sessions = [];

  /// Registers [session]; false if it already was.
  @protected
  bool addSession(VoipSession session) {
    if (_sessions.contains(session)) return false;
    _sessions.add(session);
    return true;
  }

  /// Forgets [session]; false if it was not registered.
  @protected
  bool removeSession(VoipSession session) => _sessions.remove(session);

  /// Whether a call is currently using the DSP.
  bool get isInCall => _sessions.isNotEmpty;

  /// Whether the microphone test is running (see [startMicTest]).
  bool get isTesting;

  /// Whether the microphone test plays the processed microphone back.
  bool get micTestMonitor;

  /// Level and gate state, about ten times a second while [isActive].
  Stream<AudioDspReport> get onReport => _reports.stream;

  /// Fires when [isActive], [isInCall], [isTesting] or [micTestMonitor]
  /// change.
  Stream<void> get onStateChanged => _stateChanged.stream;

  // Reports keep coming while the frame counter is stuck if the hook stops
  // receiving audio, so liveness is judged by the counter.
  static const Duration _liveWindow = Duration(milliseconds: 500);
  int _lastFrames = -1;
  DateTime? _framesAdvancedAt;
  DateTime? _gateOpenAt;
  AudioDspReport? _lastReport;

  /// Whether the DSP is processing microphone audio right now, which makes
  /// its gate the judge of what actually leaves the client.
  bool get isProcessing {
    final t = _framesAdvancedAt;
    return isActive && t != null && DateTime.now().difference(t) < _liveWindow;
  }

  /// Last time the input gate was seen open, i.e. the microphone was being
  /// sent at full gain. The gate holds for 150 ms and reports come every
  /// 100 ms, so no opening is missed.
  DateTime? get lastGateOpenAt => _gateOpenAt;

  /// The most recent report, null until the DSP has run.
  AudioDspReport? get lastReport => _lastReport;

  AudioDspSettings get settings => _lastSettings;

  /// Called by [CallManager] for every session that starts.
  Future<void> onSessionStarted(VoipSession session);

  /// Called by [CallManager] for every session that ends. The DSP comes off
  /// once none of the sessions it was told about is left.
  Future<void> onSessionEnded(VoipSession session);

  /// Web only: a processor to hand to `AudioCaptureOptions`. Null elsewhere.
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor();

  /// A microphone capture that is not a LiveKit track (a legacy 1:1 call),
  /// captured with WebRTC's own suppressor off because ours runs: the
  /// stream to send instead, or null if ours could not start on it.
  /// Native platforms process every capture inside WebRTC already and hand
  /// the stream back; the web runs it through the AudioWorklet.
  Future<webrtc.MediaStream?> processMicrophoneStream(
          webrtc.MediaStream stream) async =>
      stream;

  /// Push new tunables into a running DSP.
  Future<void> applySettings(AudioDspSettings settings);

  /// The noise suppression preference flipped. The WebRTC / browser
  /// suppressor is chosen when a capture starts (off when ours is on), so a
  /// running capture has to be restarted for the change to be complete.
  Future<void> onNoiseSuppressionChanged(bool enabled) async {}

  /// Capture the microphone through the DSP without a call, so the settings
  /// page can show the live level. Returns false if it could not start (no
  /// DSP, no microphone, or a call is in progress).
  Future<bool> startMicTest();

  Future<void> stopMicTest();

  /// Play the processed microphone back during the test. Headphones
  /// recommended.
  Future<void> setMicTestMonitor(bool enabled);

  bool _recoveryLogged = false;

  void publishReport(AudioDspReport report) {
    if (report.recovered && !_recoveryLogged) {
      _recoveryLogged = true;
      Log.w("Voice DSP: a sample that was not a number reached it, and it "
          "rebuilt its state (the microphone would have gone silent)");
    }
    _lastReport = report;
    if (report.frames != _lastFrames) {
      _lastFrames = report.frames;
      // Zero is a DSP that has not had a block yet: a new one, or one whose
      // capture just restarted. Counting that as progress made isProcessing
      // true for half a second with no audio at all, which the call's
      // watchdog takes as the DSP working.
      if (report.frames > 0) {
        final now = DateTime.now();
        _framesAdvancedAt = now;
        if (report.gateOpen) _gateOpenAt = now;
      }
    }

    if (_reports.hasListener) {
      _reports.add(report);
    }
  }

  void notifyStateChanged() {
    if (!_stateChanged.isClosed) _stateChanged.add(null);
  }

  void dispose() {
    _settingsSubscription?.cancel();
    _reports.close();
    _stateChanged.close();
  }
}
