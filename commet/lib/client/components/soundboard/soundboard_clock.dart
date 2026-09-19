// How far each sender's clock is from ours, so staleness is judged without
// trusting a sender's wall clock.
//
// A trigger carries its sender's wall-clock timestamp, and the receiver drops
// it once it is older than [SoundboardConstraints.eventTtl] (so a trigger
// queued across a reconnect does not play late). Compared against the
// receiver's own clock, that dropped everything from someone whose clock was
// off by more than a few seconds, in both directions: a dual-boot machine
// whose clock is hours out could neither hear nor be heard.
//
// Instead, every message from a sender is a sample of `our now - their
// timestamp`: delivery time plus the gap between the two clocks. The smallest
// recent sample is the gap plus the fastest delivery, and a trigger counts as
// stale when it arrives more than the TTL later than that. Clients exchange a
// clock message on joining a call (see SoundboardSession), so the gap is
// known before anyone clicks. For a sender we have no samples from (an older
// client), the plain wall-clock check is all there is.
import 'dart:math';

import 'soundboard_constraints.dart';
import 'soundboard_event.dart';

class SoundboardClocks {
  SoundboardClocks({this.window = const Duration(minutes: 10)});

  /// How long a sample counts. Bounded, so a sender whose clock is corrected
  /// (it jumped back) is judged afresh within this.
  final Duration window;

  final Map<String, List<({int atMs, int offsetMs})>> _samples = {};

  /// Records a message from [sender] stamped [timestampMs] arriving [nowMs].
  void observe(String sender, int timestampMs, int nowMs) {
    if (sender.isEmpty) return;
    final samples = _samples.putIfAbsent(sender, () => []);
    samples.add((atMs: nowMs, offsetMs: nowMs - timestampMs));
    _prune(samples, nowMs);
  }

  /// `our clock - their clock`, plus their fastest recent delivery; null when
  /// nothing recent was heard from [sender].
  int? offsetOf(String sender, int nowMs) {
    final samples = _samples[sender];
    if (samples == null) return null;
    _prune(samples, nowMs);
    if (samples.isEmpty) return null;
    return samples.map((s) => s.offsetMs).reduce(min);
  }

  /// Whether [event] from [sender] is recent enough to play.
  bool isFresh(SoundboardEvent event, String sender, int nowMs) {
    final offset = offsetOf(sender, nowMs);
    if (offset == null) return event.isFresh(nowMs);
    // Faster than the fastest delivery so far is fine: the gap is smaller
    // than we thought.
    final lateBy = (nowMs - event.timestampMs) - offset;
    return lateBy <= SoundboardConstraints.eventTtl.inMilliseconds;
  }

  void _prune(List<({int atMs, int offsetMs})> samples, int nowMs) {
    samples.removeWhere((s) => nowMs - s.atMs > window.inMilliseconds);
  }
}
