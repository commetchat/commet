import 'dart:async';

import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// getUserMedia audio constraints for a microphone capture that is not a
/// LiveKit track: the microphone test and legacy 1:1 calls. Built the way
/// LiveKit builds a voice room's (AudioCaptureOptions), so every capture asks
/// for the same processing and names its device the same way. That way
/// matters: flutter-webrtc on desktop only selects an input from
/// `optional: [{sourceId}]`, and records from its device 0, whatever the
/// user picked, for anything else (`deviceId: {exact: ...}` included).
Map<String, dynamic> microphoneConstraints({
  required bool webrtcNoiseSuppression,
  String? deviceId,
}) =>
    lk.AudioCaptureOptions(
      deviceId: deviceId,
      noiseSuppression: webrtcNoiseSuppression,
    ).toMediaConstraintsMap();

/// A call's microphone capture, as [MicrophoneNoiseSuppression] needs it.
abstract class MicrophoneCapture {
  /// Published and not muted: what it captures is being sent.
  bool get live;

  /// Whether WebRTC's own noise suppressor (the browser's, on the web) runs
  /// on this capture. Fixed when the capture is created.
  bool get webrtcNoiseSuppression;

  /// Recreates the capture with WebRTC's suppressor on or off.
  Future<void> restart({required bool webrtcNoiseSuppression});
}

/// Who takes the background noise out of a call's microphone, kept true for
/// the whole call: our DSP when the preference asks for it and the DSP can
/// run, WebRTC's (the browser's) own suppressor otherwise. Never both (voices
/// sound hollow) and never neither (the noise goes out).
///
/// WebRTC's suppressor is a capture option, so a change of who suppresses is
/// a restart of the capture, and that only happens while the microphone is
/// live: a muted capture is disabled, and a restart would bring it back
/// enabled. [update] is called whenever something may have changed (the
/// preference, an unmute, the microphone being published) and once a second,
/// and catches up then. It also watches our DSP: supported, asked for, and
/// fed no audio for [stallLimit] of live microphone, it is given up on for
/// the rest of the call and WebRTC's suppressor goes back on.
class MicrophoneNoiseSuppression {
  final AudioProcessingManager dsp;
  final MicrophoneCapture? Function() microphone;
  final bool Function() preference;

  /// Told once, when our DSP is given up on.
  final void Function()? onDspFailed;

  final DateTime Function() _now;

  /// Whether the capture itself hands audio over (MicrophoneHealthMonitor),
  /// null when not known. A capture that went quiet starves our DSP as
  /// well, and giving up on the DSP for it used to spend the one fallback
  /// of the call on something the DSP did not do. The DSP is only judged
  /// while this says true.
  final bool? Function()? captureFlowing;

  MicrophoneNoiseSuppression({
    required this.dsp,
    required this.microphone,
    required this.preference,
    this.onDspFailed,
    this.captureFlowing,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const stallLimit = Duration(seconds: 4);

  /// A restart that failed is not tried again for this long, rather than
  /// once a second.
  static const retryAfter = Duration(seconds: 10);

  /// Whether a capture created now should have WebRTC's own suppressor on.
  static bool webrtcSuppressorFor(AudioProcessingManager dsp,
          {required bool preference}) =>
      !(dsp.isSupported && preference);

  bool _dspFailed = false;
  DateTime? _stalledSince;
  Future<void>? _restarting;
  DateTime? _failedAt;

  /// Our DSP got no audio during this call and WebRTC's suppressor has taken
  /// over until the call ends.
  bool get dspFailed => _dspFailed;

  /// Whether the capture should have WebRTC's own suppressor on right now.
  bool get wantWebrtcSuppressor =>
      webrtcSuppressorFor(dsp, preference: preference()) || _dspFailed;

  /// Checks on our DSP, then brings the capture in line.
  Future<void> update() {
    _watch();
    return _reconcile();
  }

  void _watch() {
    if (_dspFailed) return;
    final mic = microphone();
    if (!dsp.isSupported || !preference() || mic == null || !mic.live) {
      _stalledSince = null;
      return;
    }
    // With a microphone watch, only a capture known to flow can starve the
    // DSP: stalled, just repaired or not known yet, it is the watch's.
    final flowing = captureFlowing;
    if (dsp.isProcessing || (flowing != null && flowing() != true)) {
      _stalledSince = null;
      return;
    }
    final since = _stalledSince ??= _now();
    if (_now().difference(since) < stallLimit) return;
    _dspFailed = true;
    Log.w("Voice DSP: no microphone audio reached it in "
        "${stallLimit.inSeconds} s of live microphone; turning WebRTC's "
        "noise suppression back on for this call");
    onDspFailed?.call();
  }

  Future<void> _reconcile() async {
    final pending = _restarting;
    if (pending != null) return pending;
    final mic = microphone();
    if (mic == null || !mic.live) return;
    final want = wantWebrtcSuppressor;
    if (mic.webrtcNoiseSuppression == want) return;
    final failedAt = _failedAt;
    if (failedAt != null && _now().difference(failedAt) < retryAfter) return;

    final restart = _restarting = _restart(mic, want);
    try {
      await restart;
    } finally {
      _restarting = null;
    }
  }

  Future<void> _restart(MicrophoneCapture mic, bool want) async {
    try {
      await mic.restart(webrtcNoiseSuppression: want);
      _failedAt = null;
      Log.i("Voice DSP: restarted the microphone, WebRTC noise suppression "
          "${want ? "on" : "off"}");
    } catch (e, s) {
      _failedAt = _now();
      Log.onError(e, s, content: "Voice DSP: could not restart microphone");
    }
  }
}
