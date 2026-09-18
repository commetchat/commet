// Keeps the state listed in our own call membership (issue #9) in step with
// what we publish and whether we have silenced ourselves, without hammering
// the homeserver: state writes share the message rate limit (Synapse's
// default is 0.2/s with a burst of 10).
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/debug/log.dart';

/// What our call membership advertises about us. Written as one value, since
/// every write rewrites the whole state event and two writers would clobber
/// each other.
class CallMembershipState {
  const CallMembershipState({
    this.media = const {},
    this.voice = const {},
  });

  /// What we publish: screen share, camera.
  final Set<LiveMedia> media;

  /// How we have silenced ourselves: muted, deafened.
  final Set<VoiceState> voice;

  static const _media = SetEquality<LiveMedia>();
  static const _voice = SetEquality<VoiceState>();

  @override
  bool operator ==(Object other) =>
      other is CallMembershipState &&
      _media.equals(media, other.media) &&
      _voice.equals(voice, other.voice);

  @override
  int get hashCode => Object.hash(_media.hash(media), _voice.hash(voice));

  @override
  String toString() => "CallMembershipState(media: $media, voice: $voice)";
}

class CallMembershipPublisher {
  CallMembershipPublisher({
    required Future<void> Function(CallMembershipState state) write,
    this.debounce = const Duration(milliseconds: 750),
    this.minInterval = const Duration(seconds: 2),
    this.maxBackoff = const Duration(minutes: 1),
  }) : _write = write;

  final Future<void> Function(CallMembershipState state) _write;

  /// How long a value must stay unchanged before it is written.
  final Duration debounce;

  /// Least time between two writes; doubles after each failed write, up to
  /// [maxBackoff].
  final Duration minInterval;
  final Duration maxBackoff;

  /// The join write lists nothing.
  CallMembershipState _written = const CallMembershipState();
  CallMembershipState _desired = const CallMembershipState();
  Timer? _debounceTimer;
  Timer? _cooldownTimer;
  Future<void>? _inFlight;
  int _failures = 0;
  bool _stopped = false;

  /// What we advertise now. Written once it has stayed the same for
  /// [debounce], one write at a time and at most one per [minInterval];
  /// a value equal to the last one written isn't written again.
  void update(CallMembershipState state) {
    if (_stopped) return;
    _desired = state;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      _debounceTimer = null;
      _flush();
    });
  }

  void _flush() {
    if (_stopped ||
        _debounceTimer != null ||
        _inFlight != null ||
        _cooldownTimer != null) {
      return;
    }
    if (_desired == _written) return;

    final sending = _send(_desired);
    _inFlight = sending;
    sending.whenComplete(() {
      if (identical(_inFlight, sending)) _inFlight = null;
    });
  }

  Future<void> _send(CallMembershipState state) async {
    var wait = minInterval;
    try {
      await _write(state);
      _written = state;
      _failures = 0;
    } catch (e) {
      _failures++;
      Log.w("Could not publish call membership state (attempt $_failures): $e");
      final backoff = minInterval * pow(2, _failures - 1).toInt();
      wait = backoff > maxBackoff ? maxBackoff : backoff;
    }

    if (_stopped) return;
    _cooldownTimer = Timer(wait, () {
      _cooldownTimer = null;
      _flush();
    });
  }

  /// Stops publishing: drops what is pending and waits for the write in
  /// flight, so nothing lands after the caller clears the membership.
  Future<void> stop() async {
    _stopped = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    await _inFlight;
  }
}
