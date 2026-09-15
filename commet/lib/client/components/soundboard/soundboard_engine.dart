// Session playback state machine. Pure Dart — no Flutter/media_kit here,
// so unit tests run with `dart test`. The real audio sink is injected via
// [SoundboardPlayer]; UI subscribes to [activeSounds] snapshots.
//
// Semantics (spec):
// - Different sounds: polyphonic (coexist in [active]).
// - Same soundId: restart — previous instance stops, new one starts at 0.
// - Same soundId from another user: still restart; author becomes latest.
// - Local optimistic play: caller plays immediately, then sends; echo of own
//   eventId is ignored via [ownEventIds] (no double-play).
// - No global `currentSound`; [active] is a Map keyed by soundId.
import 'soundboard_constraints.dart';
import 'soundboard_dedup.dart';
import 'soundboard_event.dart';

/// Minimal audio sink seam. Production adapter wraps media_kit Players;
/// tests use a fake recording calls.
abstract class SoundboardPlayer {
  Future<void> start(String soundId);
  Future<void> stop(String soundId);
  Future<void> stopAll();
  Future<void> setVolumeFor(String soundId, double volume);
  bool isPlaying(String soundId);
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

  /// soundId -> ActiveSound. Never a single global currentSound.
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
  })  : dedup = dedup ?? SoundboardDedup(),
        nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

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
    if (!event.isFresh(now)) return false;
    _startPlayback(
      soundId: event.soundId,
      senderId: (authenticatedSenderId?.isNotEmpty == true)
          ? authenticatedSenderId!
          : event.senderId,
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
    // Same-sound restart: stop previous instance first (no layering of the
    // same soundId, matching MyInstants behavior).
    if (active.containsKey(soundId)) {
      player.stop(soundId);
    }
    player.setVolumeFor(soundId, _userVolume);
    player.start(soundId);
    active[soundId] = ActiveSound(
      soundId: soundId,
      senderId: senderId,
      eventId: eventId,
      startedAtMs: now,
      overlayMs: clampOverlayMs(soundDurationMs),
    );
    _notify();
  }

  /// Called by audio completion / overlay timer.
  void markFinished(String soundId, {bool stopAudio = false}) {
    if (stopAudio) player.stop(soundId);
    if (active.remove(soundId) != null) _notify();
  }

  /// Sound finished naturally (audio ended). Overlay may linger briefly;
  /// UI decides via [ActiveSound.startedAtMs]/[overlayMs].
  void onAudioCompleted(String soundId) => markFinished(soundId);

  static int clampOverlayMs(int? soundDurationMs) {
    final d = soundDurationMs ?? SoundboardConstraints.minOverlayMs;
    return d.clamp(SoundboardConstraints.minOverlayMs,
        SoundboardConstraints.maxOverlayMs);
  }

  Future<void> dispose() async {
    await player.stopAll();
    active.clear();
    _ownEventIds.clear();
    _listeners.clear();
  }
}
