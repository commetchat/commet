// Whether the microphone of a call is still getting through, and what to do
// when it is not.
//
// A call that lost its microphone used to stay that way until the user left
// and rejoined: nobody hears their own microphone, and nothing in the app
// looked. The ways it got lost (docs/voice-call-health.md):
//
// - Windows: WebRTC's audio device module ends its capture thread for good
//   on any WASAPI error or a half second without audio (a Bluetooth headset
//   switching profiles, a USB hiccup, sleep, a driver reset, another program
//   taking the device), while it keeps saying it is recording, so nothing
//   starts it again. Linux PulseAudio has the same failure when its stream
//   is killed.
// - A restart of the capture that could not open the device.
// - The browser ending the microphone track (the device went away).
//
// [MicrophoneHealthMonitor] looks once a second, from what WebRTC itself
// counts, and repairs step by step: the cheapest repair first, and the
// whole microphone published again last.
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:commet/debug/log.dart';

/// What a call can see of its own microphone at one moment.
class MicrophoneVitals {
  const MicrophoneVitals({
    required this.sending,
    this.missing = false,
    this.captureEnded = false,
    this.capturedSeconds,
    this.packetsSent,
    this.talking = false,
    this.processing = true,
  });

  /// The user means to be heard: the microphone is published and neither
  /// muted nor deafened. Nothing is judged otherwise.
  final bool sending;

  /// The user means to be heard and the microphone they had is no longer
  /// published at all.
  final bool missing;

  /// The capture track has ended: the device went away, or the browser or
  /// the platform stopped it.
  final bool captureEnded;

  /// How much audio the sender has been handed from the capture so far, in
  /// seconds (WebRTC's `media-source` `totalSamplesDuration`), or null when
  /// that cannot be read. It grows with real time while audio flows, speech
  /// or silence alike, and stops when the capture does.
  final double? capturedSeconds;

  /// RTP packets sent for the microphone so far (`outbound-rtp`), or null.
  final int? packetsSent;

  /// The voice DSP hears the user speaking right now (its input gate is
  /// open). With discontinuous transmission a microphone sends next to
  /// nothing while the user is quiet, so packets are only expected then.
  final bool talking;

  /// The voice DSP on the capture, where there is one, handles its audio.
  /// On the web it sits between the capture and the sender, and when it
  /// stops (its worker failed, its audio context stopped) the sender gets
  /// silence, however well the capture itself goes.
  final bool processing;

  static const none = MicrophoneVitals(sending: false);
}

enum MicrophoneFault {
  /// The microphone is no longer published.
  missing,

  /// The capture track ended.
  captureEnded,

  /// The capture hands the sender no audio.
  captureStalled,

  /// The user speaks and nothing is sent.
  sendStalled,

  /// The voice DSP between the capture and the sender stopped.
  processingStalled,
}

/// Repairs, cheapest first.
enum MicrophoneRepair {
  /// Turn the capture off and on again. Desktop: that stops and restarts
  /// WebRTC's recording, which brings back a capture thread that died.
  reopen,

  /// Open a new capture of the same microphone for the same sender.
  restart,

  /// Unpublish the microphone and publish a new one: a new sender.
  republish,
}

class MicrophoneHealthMonitor {
  MicrophoneHealthMonitor({
    required Future<MicrophoneVitals> Function() read,
    required Future<void> Function(MicrophoneRepair repair) repair,
    this.ladder = MicrophoneRepair.values,
    this.onGaveUp,
    this.onRecovered,
    DateTime Function()? now,
  })  : assert(ladder.isNotEmpty),
        _read = read,
        _repair = repair,
        _now = now ?? DateTime.now;

  final Future<MicrophoneVitals> Function() _read;
  final Future<void> Function(MicrophoneRepair repair) _repair;
  final DateTime Function() _now;

  /// The repairs this platform has, tried in this order. The last one is
  /// repeated, spaced out by [retryBackoff], for as long as the fault lasts.
  final List<MicrophoneRepair> ladder;

  /// Told once every repair was tried and the microphone is still not
  /// getting through; the user has to know.
  final void Function(MicrophoneFault fault)? onGaveUp;

  /// Told when a microphone that needed repairs works again.
  final void Function()? onRecovered;

  /// Nothing is judged this soon after the microphone started sending
  /// (published, unmuted) or after a repair: WebRTC restarts recording and
  /// its statistics lag behind.
  static const settle = Duration(seconds: 3);

  /// The capture is judged on this much time.
  static const stallWindow = Duration(seconds: 2);

  /// Less audio than this per second of real time is a stalled capture. A
  /// working one hands over one second per second.
  static const minCaptureRate = 0.25;

  /// Speaking for this long while no packet leaves is a stalled sender.
  static const talkingWithoutPackets = Duration(seconds: 3);

  /// A repair that has not finished by then counts as failed, so one hung
  /// platform call does not stop the watch.
  static const repairTimeout = Duration(seconds: 10);

  /// Spacing of the repeats once the whole ladder was tried.
  static const retryBackoff = [
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 40),
    Duration(seconds: 60),
  ];

  DateTime? _sendingSince;
  DateTime? _settledAt;
  final List<({DateTime at, double seconds})> _captured = [];

  int? _packets;
  Duration _talkingWithoutPackets = Duration.zero;
  DateTime? _notProcessingSince;
  DateTime? _missingSince;
  DateTime? _lastCheck;

  int _attempts = 0;
  DateTime? _nextRepairAt;
  bool _gaveUp = false;
  bool _checking = false;

  MicrophoneFault? _fault;
  bool? _captureFlowing;

  /// Whether the capture handed the sender audio over the last
  /// [stallWindow]: false for a stalled or ended capture, null when that is
  /// not known (not sending, just started, no statistics). The noise
  /// suppression watchdog asks, so a dead capture is not taken for a dead
  /// DSP.
  bool? get captureFlowing => _captureFlowing;

  /// What was wrong at the last check, null when the microphone was fine
  /// or not judged.
  MicrophoneFault? get fault => _fault;

  /// Repairs made since the microphone last worked.
  int get attempts => _attempts;

  /// Looks at the microphone once and repairs it if it needs it. Called
  /// once a second; a check still running (a repair takes a moment) makes
  /// the next one a no-op.
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      await _check();
    } finally {
      _checking = false;
    }
  }

  /// A read that has not answered by then (a platform call that hangs)
  /// is skipped: the watch must go on.
  static const readTimeout = Duration(seconds: 5);

  Future<void> _check() async {
    final MicrophoneVitals vitals;
    try {
      vitals = await _read().timeout(readTimeout);
    } catch (e, s) {
      Log.onError(e, s, content: "Voice: could not read the microphone");
      return;
    }
    final now = _now();
    final sinceLast = _lastCheck == null ? Duration.zero : now - _lastCheck!;
    _lastCheck = now;

    if (!vitals.sending && !vitals.missing) {
      // Muting stops the capture on desktop and unmuting starts it again,
      // which is itself a repair: start over.
      _forget();
      _fault = null;
      _captureFlowing = null;
      _attempts = 0;
      _nextRepairAt = null;
      _gaveUp = false;
      return;
    }

    _sendingSince ??= now;
    if (vitals.missing) {
      _missingSince ??= now;
    } else {
      _missingSince = null;
    }
    _observe(vitals, now, sinceLast);
    _captureFlowing = vitals.captureEnded ? false : _captureRateOk(now);

    final settledAt = _settledAt ?? _sendingSince!.add(settle);
    if (now.isBefore(settledAt)) return;

    // Gone for a moment is LiveKit republishing after a reconnect.
    final missing = _missingSince;
    if (missing != null && now.difference(missing) < settle) return;

    final fault = _judge(vitals, now);
    _fault = fault;
    if (fault == null) {
      if (_attempts > 0) {
        Log.i("Voice: the microphone gets through again "
            "(after $_attempts repair${_attempts == 1 ? "" : "s"})");
        onRecovered?.call();
      }
      _attempts = 0;
      _nextRepairAt = null;
      _gaveUp = false;
      return;
    }

    final next = _nextRepairAt;
    if (next != null && now.isBefore(next)) return;

    // Nothing to reopen or restart without a microphone.
    final repair = fault == MicrophoneFault.missing
        ? MicrophoneRepair.republish
        : ladder[min(_attempts, ladder.length - 1)];
    Log.w("Voice: microphone fault ${fault.name}, repairing it "
        "(${repair.name}, attempt ${_attempts + 1})");
    try {
      await _repair(repair).timeout(repairTimeout);
    } catch (e, s) {
      Log.onError(e, s,
          content: "Voice: the microphone repair ${repair.name} failed");
    }
    _attempts++;

    final after = _now();
    _forget();
    _captureFlowing = null;
    _sendingSince = after;
    _settledAt = after.add(settle);
    if (_attempts >= ladder.length) {
      final wait =
          retryBackoff[min(_attempts - ladder.length, retryBackoff.length - 1)];
      _nextRepairAt = after.add(wait);
      if (!_gaveUp) {
        _gaveUp = true;
        Log.w("Voice: every microphone repair was tried and it still does "
            "not get through (${fault.name}); trying again every "
            "${wait.inSeconds} s or more");
        onGaveUp?.call(fault);
      }
    }
  }

  void _forget() {
    _sendingSince = null;
    _settledAt = null;
    _captured.clear();
    _packets = null;
    _talkingWithoutPackets = Duration.zero;
    _notProcessingSince = null;
    _missingSince = null;
  }

  void _observe(MicrophoneVitals vitals, DateTime now, Duration sinceLast) {
    final seconds = vitals.capturedSeconds;
    if (seconds != null) {
      // A new sender (a republish) counts from zero again.
      if (_captured.isNotEmpty && seconds < _captured.last.seconds) {
        _captured.clear();
      }
      _captured.add((at: now, seconds: seconds));
      // Keep the newest sample old enough to judge on, and what came after.
      final base =
          _captured.lastIndexWhere((s) => now.difference(s.at) >= stallWindow);
      if (base > 0) _captured.removeRange(0, base);
    }

    if (vitals.processing) {
      _notProcessingSince = null;
    } else {
      _notProcessingSince ??= now;
    }

    final packets = vitals.packetsSent;
    if (packets == null || packets != _packets) {
      _packets = packets;
      _talkingWithoutPackets = Duration.zero;
    } else if (vitals.talking) {
      _talkingWithoutPackets += sinceLast;
    }
  }

  /// Whether the capture kept up over [stallWindow], null without enough
  /// samples.
  bool? _captureRateOk(DateTime now) {
    final base =
        _captured.firstWhereOrNull((s) => now.difference(s.at) >= stallWindow);
    if (base == null) return null;
    final latest = _captured.last;
    final elapsed = latest.at.difference(base.at).inMilliseconds / 1000;
    if (elapsed <= 0) return null;
    return (latest.seconds - base.seconds) / elapsed >= minCaptureRate;
  }

  MicrophoneFault? _judge(MicrophoneVitals vitals, DateTime now) {
    if (_missingSince != null) return MicrophoneFault.missing;
    if (vitals.captureEnded) return MicrophoneFault.captureEnded;
    if (_captureRateOk(now) == false) return MicrophoneFault.captureStalled;
    final notProcessing = _notProcessingSince;
    if (notProcessing != null && now.difference(notProcessing) >= stallWindow) {
      return MicrophoneFault.processingStalled;
    }

    if (_talkingWithoutPackets >= talkingWithoutPackets) {
      return MicrophoneFault.sendStalled;
    }
    return null;
  }
}

extension on DateTime {
  Duration operator -(DateTime other) => difference(other);
}
