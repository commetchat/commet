// Session playback state machine. Pure Dart — no Flutter/media_kit here,
// so unit tests run with `dart test`. The real audio sink is injected via
// [SoundboardPlayer]; UI subscribes to [activeSounds] snapshots.
//
// Semantics (spec, Discord-like):
// - Every trigger is an independent instance keyed by its eventId, so the
//   same sound from one or several users overlaps; nothing is interrupted.
// - Local optimistic play: caller plays immediately, then sends; echo of own
//   eventId is ignored via [ownEventIds] (no double-play).
// - No global `currentSound`; [active] is a Map keyed by eventId.
import 'soundboard_clock.dart';
import 'soundboard_constraints.dart';
import 'soundboard_dedup.dart';
import 'soundboard_event.dart';

/// Minimal audio sink seam. Production adapter wraps media_kit Players;
/// tests use a fake recording calls.
/// Instances are keyed by [instanceId] (the trigger's eventId); one sound
/// may have several live instances.
abstract class SoundboardPlayer {
  Future<void> start(String instanceId, String soundId);
  Future<void> stop(String instanceId);
  Future<void> stopAll();
  Future<void> setVolumeFor(String instanceId, double volume);
  bool isPlaying(String instanceId);
}

/// One visible/audible activation (drives emoji overlay).
class ActiveSound {
  final String soundId;
  final String senderId;
  final String eventId;
  final int startedAtMs;
  final int overlayMs;

  const ActiveSound({
    required this.soundId,
    required this.senderId,
    required this.eventId,
    required this.startedAtMs,
    required this.overlayMs,
  });
}

typedef NowMs = int Function();

class SoundboardEngine {
  final SoundboardPlayer player;
  final SoundboardDedup dedup;
  final NowMs nowMs;

  /// Each sender's clock offset, for judging staleness (the session feeds
  /// it the clock messages).
  final SoundboardClocks clocks;

  /// eventId -> ActiveSound, in start order. Never a single global
  /// currentSound.
  final Map<String, ActiveSound> active = {};

  /// EventIds produced locally; echoes arriving via transport are dropped.
  final Set<String> _ownEventIds = {};

  double _userVolume = 0.8;
  double get userVolume => _userVolume;

  final List<void Function()> _listeners = [];

  SoundboardEngine({
    required this.player,
    SoundboardDedup? dedup,
    NowMs? nowMs,
    SoundboardClocks? clocks,
  })  : dedup = dedup ?? SoundboardDedup(),
        nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch),
        clocks = clocks ?? SoundboardClocks();

  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void setVolume(double volume) {
    _userVolume = volume.clamp(0.0, 1.5);
    for (final id in active.keys) {
      player.setVolumeFor(id, _userVolume);
    }
  }

  /// Local click path: play immediately (no network wait), return the event
  /// to send. Caller transmits it; the echo will be dropped by [onRemoteEvent].
  SoundboardEvent localTrigger({
    required String soundId,
    required String senderId,
    required String eventId,
    int? soundDurationMs,
  }) {
    final now = nowMs();
    _ownEventIds.add(eventId);
    if (_ownEventIds.length > SoundboardConstraints.maxDedupEntries) {
      _ownEventIds.remove(_ownEventIds.first);
    }
    dedup.checkAndRemember(eventId, now);
    _startPlayback(
      soundId: soundId,
      senderId: senderId,
      eventId: eventId,
      now: now,
      soundDurationMs: soundDurationMs,
    );
    return SoundboardEvent(
      soundId: soundId,
      senderId: senderId,
      eventId: eventId,
      timestampMs: now,
    );
  }

  /// Remote path. Returns true if playback started.
  /// [authenticatedSenderId], when available from the transport (LiveKit
  /// identity / Matrix sender), overrides the payload hint.
  Future<bool> onRemoteEvent(
    SoundboardEvent event, {
    String? authenticatedSenderId,
    int? soundDurationMs,
  }) async {
    final now = nowMs();
    if (_ownEventIds.remove(event.eventId)) return false; // own echo
    if (dedup.checkAndRemember(event.eventId, now)) return false;
    final sender = (authenticatedSenderId?.isNotEmpty == true)
        ? authenticatedSenderId!
        : event.senderId;
    if (!clocks.isFresh(event, sender, now)) return false;
    clocks.observe(sender, event.timestampMs, now);
    _startPlayback(
      soundId: event.soundId,
      senderId: sender,
      eventId: event.eventId,
      now: now,
      soundDurationMs: soundDurationMs,
    );
    return true;
  }

  void _startPlayback({
    required String soundId,
    required String senderId,
    required String eventId,
    required int now,
    int? soundDurationMs,
  }) {
    while (active.length >= SoundboardConstraints.maxConcurrentInstances) {
      markFinished(active.keys.first, stopAudio: true);
    }
    // Record before starting: the player may report the instance finished
    // synchronously (e.g. unknown sound).
    active[eventId] = ActiveSound(
      soundId: soundId,
      senderId: senderId,
      eventId: eventId,
      startedAtMs: now,
      overlayMs: clampOverlayMs(soundDurationMs),
    );
    _notify();
    player.setVolumeFor(eventId, _userVolume);
    player.start(eventId, soundId);
  }

  /// Called by audio completion / overlay timer.
  void markFinished(String eventId, {bool stopAudio = false}) {
    if (stopAudio) player.stop(eventId);
    if (active.remove(eventId) != null) _notify();
  }

  /// Sound finished naturally (audio ended). Overlay may linger briefly;
  /// UI decides via [ActiveSound.startedAtMs]/[overlayMs].
  void onAudioCompleted(String eventId) => markFinished(eventId);

  static int clampOverlayMs(int? soundDurationMs) {
    final d = soundDurationMs ?? SoundboardConstraints.minOverlayMs;
    return d.clamp(
        SoundboardConstraints.minOverlayMs, SoundboardConstraints.maxOverlayMs);
  }

  Future<void> dispose() async {
    await player.stopAll();
    active.clear();
    _ownEventIds.clear();
    _listeners.clear();
  }
}
