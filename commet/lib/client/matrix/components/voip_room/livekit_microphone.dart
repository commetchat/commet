// The microphone of a LiveKit voice room: how it is created and found.
// Every microphone capture of a room goes through here, so who suppresses
// noise on it (MicrophoneNoiseSuppression) is decided in one place.
import 'package:collection/collection.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/microphone_noise_suppression.dart';
import 'package:commet/client/components/voip/audio_processing/noise_suppression_notice.dart';
import 'package:commet/client/components/voip/audio_processing/shared_audio_processing.dart';
import 'package:commet/client/components/voip/microphone_health.dart';
import 'package:commet/client/components/voip/webrtc_microphone.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;

/// Capture options for a room's microphone. WebRTC's (the browser's) own
/// noise suppressor only when ours will not run; on the web ours is the
/// track processor (native platforms hook into WebRTC's pipeline instead
/// and have none).
lk.AudioCaptureOptions microphoneCaptureOptions({
  required AudioProcessingManager dsp,
  required bool noiseSuppressionPreference,
  String? deviceId,
}) =>
    lk.AudioCaptureOptions(
      deviceId: deviceId,
      noiseSuppression: MicrophoneNoiseSuppression.webrtcSuppressorFor(dsp,
          preference: noiseSuppressionPreference),
      processor: dsp.createTrackProcessor(),
    );

/// A room microphone's capture options, once it is known whether our DSP
/// can run (on the web that means audio_dsp.wasm fetched and test-run). A
/// user who asked for noise suppression and cannot have ours is told.
Future<lk.AudioCaptureOptions> prepareMicrophoneCaptureOptions({
  required AudioProcessingManager dsp,
  required bool noiseSuppressionPreference,
  String? deviceId,
}) async {
  final ready = await dsp.ensureReady();
  final reason = dsp.unavailableReason;
  if (noiseSuppressionPreference && !ready && reason != null) {
    warnNoiseSuppressionUnavailable(reason);
  }
  return microphoneCaptureOptions(
    dsp: dsp,
    noiseSuppressionPreference: noiseSuppressionPreference,
    deviceId: deviceId,
  );
}

/// Options for `setMicrophoneEnabled` when the user mutes or unmutes.
///
/// A published microphone keeps what it captures with, told to keep
/// capturing while muted (`stopAudioCaptureOnMute` defaults to true): muting
/// otherwise closes the device, and on desktop that is a fresh getUserMedia,
/// a reset of WebRTC's shared audio processing and a teardown of the DSP
/// processor on every mute.
///
/// A microphone that was never published (the join could not: denied, or no
/// device yet) is created here by unmuting, so it gets a room microphone's
/// options, our DSP included. Left to LiveKit's defaults it went out without
/// the web DSP and with the suppressor chosen regardless of ours.
Future<lk.AudioCaptureOptions?> microphoneOptionsToToggle(
  lk.LocalParticipant? participant, {
  required bool enabling,
  required AudioProcessingManager dsp,
  required bool noiseSuppressionPreference,
  required Future<String?> Function() deviceId,
}) async {
  final track = microphonePublication(participant)?.track;
  if (track != null) {
    return track.currentOptions.copyWith(stopAudioCaptureOnMute: false);
  }
  // Muting what does not exist creates nothing, and a processor made for
  // nothing would replace the web DSP's current one.
  if (!enabling) return null;
  return (await prepareMicrophoneCaptureOptions(
    dsp: dsp,
    noiseSuppressionPreference: noiseSuppressionPreference,
    deviceId: await deviceId(),
  ))
      .copyWith(stopAudioCaptureOnMute: false);
}

/// The microphone's publication, found by its source. Not "the first audio
/// publication": that is the DJ booth's music or the screen share's audio
/// whenever those were published before the microphone was (it failed, or
/// was denied, at join), and restarting one of them with microphone
/// options replaces it with a microphone capture.
lk.LocalTrackPublication<lk.LocalAudioTrack>? microphonePublication(
        lk.LocalParticipant? participant) =>
    participant?.audioTrackPublications
        .firstWhereOrNull((p) => p.source == lk.TrackSource.microphone);

/// Changes to one call's microphone capture, one at a time. The noise
/// suppression restart and the microphone watch's repairs both replace or
/// reopen the capture; two at once opened two captures and stopped the
/// wrong one. Muting does not queue here: it must never wait.
class CaptureChanges {
  CaptureChanges({this.limit = const Duration(seconds: 15)});

  /// The next change waits this long at most for the one before: a change
  /// that never finishes (a getUserMedia left behind a permission prompt)
  /// must not hold every later repair up for the rest of the call.
  final Duration limit;

  Future<void> _last = Future.value();

  Future<T> run<T>(Future<T> Function() change) {
    final result = _last.then((_) => change());
    _last = result.then<void>((_) {}, onError: (Object _) {}).timeout(limit,
        onTimeout: () {
      Log.w("Voice: a microphone change is still running after "
          "${limit.inSeconds} s; not waiting for it any longer");
    });
    return result;
  }
}

/// A room's microphone for [MicrophoneNoiseSuppression].
class LivekitMicrophone implements MicrophoneCapture {
  final lk.LocalTrackPublication<lk.LocalAudioTrack> publication;
  final CaptureChanges? _changes;

  LivekitMicrophone(this.publication, {CaptureChanges? changes})
      : _changes = changes;

  static LivekitMicrophone? of(lk.LocalParticipant? participant,
      {CaptureChanges? changes}) {
    final publication = microphonePublication(participant);
    return publication == null
        ? null
        : LivekitMicrophone(publication, changes: changes);
  }

  @override
  bool get live => publication.track != null && !publication.muted;

  @override
  bool get webrtcNoiseSuppression =>
      publication.track?.currentOptions.noiseSuppression ?? true;

  @override
  Future<void> restart({required bool webrtcNoiseSuppression}) async {
    Future<void> restart() async {
      final track = publication.track;
      if (track == null) return;
      await track.restartTrack(track.currentOptions
          .copyWith(noiseSuppression: webrtcNoiseSuppression));
    }

    final changes = _changes;
    await (changes == null ? restart() : changes.run(restart));
    await keepMuted(publication);
  }
}

/// A mute that landed while the capture was being replaced must hold: the
/// new capture comes enabled.
Future<void> keepMuted(
    lk.LocalTrackPublication<lk.LocalAudioTrack> publication) async {
  final track = publication.track;
  if (track != null && publication.muted && track.mediaStreamTrack.enabled) {
    await track.disable();
  }
}

/// The microphone watch of a LiveKit room ([MicrophoneHealthMonitor]):
/// reads the room's microphone publication and its sender, and repairs it.
class LivekitMicrophoneHealth {
  LivekitMicrophoneHealth({
    required lk.LocalParticipant? Function() participant,
    required bool Function() wanted,
    required Future<lk.AudioCaptureOptions> Function() captureOptions,
    bool Function()? connected,
    bool Function()? talking,
    bool Function()? processing,
    CaptureChanges? changes,
    List<MicrophoneRepair>? ladder,
    void Function(MicrophoneFault fault)? onGaveUp,
    void Function()? onRecovered,
    DateTime Function()? now,
  })  : _participant = participant,
        _wanted = wanted,
        _captureOptions = captureOptions,
        _connected = connected ?? _always,
        _talking = talking,
        _processing = processing,
        _changes = changes ?? CaptureChanges() {
    monitor = MicrophoneHealthMonitor(
      read: _read,
      repair: (repair) => _changes.run(() => _repair(repair)),
      ladder: ladder ?? defaultLadder,
      onGaveUp: onGaveUp,
      onRecovered: onRecovered,
      now: now,
    );
  }

  final lk.LocalParticipant? Function() _participant;

  /// Whether the user wants to be heard (neither muted nor deafened), as
  /// the session last set it, before LiveKit has caught up.
  final bool Function() _wanted;

  /// A room microphone's capture options, for publishing a new one.
  final Future<lk.AudioCaptureOptions> Function() _captureOptions;

  /// Whether the room is connected. Nothing is judged or repaired
  /// otherwise: LiveKit unpublishes everything when it gives up, and
  /// nothing is sent while it reconnects.
  final bool Function() _connected;

  static bool _always() => true;
  final bool Function()? _talking;

  /// Whether the voice DSP handles the microphone's audio, where one sits
  /// between the capture and the sender (the web's).
  final bool Function()? _processing;
  final CaptureChanges _changes;

  /// A microphone was published in this call: one that is gone now went
  /// missing. A call that never had one (no device, permission denied) is
  /// not asked for one behind the user's back.
  bool _hadMicrophone = false;

  bool get hadMicrophone => _hadMicrophone;

  late final MicrophoneHealthMonitor monitor;

  /// The repairs this platform has: desktop can restart WebRTC's recording
  /// without a new capture; the browser cannot.
  static List<MicrophoneRepair> get defaultLadder => canReopenCapture
      ? MicrophoneRepair.values
      : const [MicrophoneRepair.restart, MicrophoneRepair.republish];

  Future<void> check() => monitor.check();

  Future<MicrophoneVitals> _read() async {
    if (!_connected()) return MicrophoneVitals.none;
    final participant = _participant();
    final publication = microphonePublication(participant);
    final track = publication?.track;
    if (participant != null && publication == null && _hadMicrophone) {
      return MicrophoneVitals(sending: false, missing: _wanted());
    }
    if (publication == null ||
        track == null ||
        publication.muted ||
        !_wanted()) {
      return MicrophoneVitals.none;
    }
    _hadMicrophone = true;
    final counters = await readSenderCounters(track.sender);
    return MicrophoneVitals(
      sending: true,
      // With a processor (the web's DSP) the track the sender carries is
      // the processed one, which never ends: the capture is the original.
      captureEnded: !track.isActive ||
          // ignore: invalid_use_of_internal_member
          captureEnded(track.originalTrack ?? track.mediaStreamTrack),
      capturedSeconds: counters.capturedSeconds,
      packetsSent: counters.packetsSent,
      talking: _talking?.call() ?? false,
      processing: _processing?.call() ?? true,
    );
  }

  Future<void> _repair(MicrophoneRepair repair) async {
    final participant = _participant();
    if (participant == null || !_wanted() || !_connected()) return;
    final publication = microphonePublication(participant);
    final track = publication?.track;
    if (publication == null || track == null) {
      // Gone: only a new one helps, whatever the step.
      await _republish(participant, null);
      return;
    }
    if (publication.muted) return;

    switch (repair) {
      case MicrophoneRepair.reopen:
        // ignore: invalid_use_of_internal_member
        await reopenCapture(track.originalTrack ?? track.mediaStreamTrack);
      case MicrophoneRepair.restart:
        await track.restartTrack();
        await keepMuted(publication);
      case MicrophoneRepair.republish:
        await _republish(participant, publication);
    }
  }

  /// A new microphone on a new sender. Other people's clients see a new
  /// publication, subscribe to it and ask for its key, as when someone
  /// joins.
  Future<void> _republish(lk.LocalParticipant participant,
      lk.LocalTrackPublication<lk.LocalAudioTrack>? old) async {
    if (old != null) await participant.removePublishedTrack(old.sid);
    // Muted meanwhile: the next unmute publishes one (it is what an unmute
    // does when there is no microphone), with the mute kept. The options
    // are made only now: on the web they carry a new DSP processor, which
    // the DSP takes for the microphone's from then on.
    if (!_wanted() || !_connected()) return;
    final options = await _captureOptions();
    if (!_wanted() || !_connected()) return;
    // Published directly, not through setMicrophoneEnabled: with no
    // microphone published LiveKit's lookup by source used to find the DJ
    // booth's music (published without a source) and unmute that instead.
    final track = await lk.LocalAudioTrack.create(
        options.copyWith(stopAudioCaptureOnMute: false));
    try {
      if (!_wanted() || !_connected()) {
        await track.stop();
        return;
      }
      final published = await participant.publishAudioTrack(track);
      if (!_wanted()) await published.mute(stopOnMute: false);
    } catch (_) {
      // The room went away meanwhile: nothing else would stop it.
      await track.stop();
      rethrow;
    }
  }
}

/// Desktop: once [custom] (screen-share audio, the DJ booth's music) has
/// written its options onto the audio processing module WebRTC shares with
/// the microphone, writes the microphone's back (see
/// shared_audio_processing.dart). A custom source writes them when its
/// sender is negotiated, which LiveKit does after announcing the
/// publication, so this waits for the sender to have outbound RTP
/// statistics, and restores anyway after [timeout].
Future<bool> restoreMicrophoneProcessingAfter(
  lk.LocalTrackPublication custom,
  lk.LocalParticipant participant, {
  bool? overridden,
  Duration timeout = const Duration(seconds: 10),
  Duration poll = const Duration(milliseconds: 100),
}) async {
  if (!(overridden ?? customAudioSourcesOverrideMicrophone)) return false;
  if (custom.kind != lk.TrackType.AUDIO ||
      custom.source == lk.TrackSource.microphone) {
    return false;
  }
  final sender = custom.track?.sender;
  if (sender != null) {
    final deadline = DateTime.now().add(timeout);
    while (!await _negotiated(sender)) {
      if (DateTime.now().isAfter(deadline)) {
        Log.w("Voice: a custom audio source was not negotiated in "
            "${timeout.inSeconds} s; restoring the microphone's processing "
            "anyway");
        break;
      }
      await Future<void>.delayed(poll);
    }
  }
  final track = microphonePublication(participant)?.track;
  if (track == null) return false;
  return restoreMicrophoneProcessing(track.mediaStreamTrack,
      overridden: overridden);
}

Future<bool> _negotiated(rtc.RTCRtpSender sender) async {
  try {
    return (await sender.getStats()).any((r) => r.type == 'outbound-rtp');
  } catch (_) {
    return false;
  }
}
