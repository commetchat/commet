// Session coordinator: catalog + engine + transport + preload + volume.
//
// One instance per joined call. Responsibilities:
// - Preload catalog audio on call join (resolve MXC -> cache file, keep LRU).
// - Local click -> engine.localTrigger (immediate) -> transport.send (async,
//   errors swallowed with logging, never modal).
// - Remote events -> engine.onRemoteEvent with authenticated sender.
// - Volume: single per-user DoubletPreference-backed value, applied to live
//   and future sounds; 0 = mute.
// - Cleanup on leave: stop audio, cancel subscriptions, clear overlays.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_cache.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:uuid/uuid.dart';

/// Non-fatal error sink (logging in production, silent in tests).
typedef SoundboardErrorSink = void Function(
    Object error, StackTrace stack, String context);

class SoundboardSession {
  final SoundboardCatalog catalog;
  final SoundboardEngine engine;
  final SoundboardTransport transport;
  final String selfUserId;

  /// Resolves a soundId to its known duration (for overlay timing).
  final int? Function(String soundId)? durationOf;

  /// Preloads a sound's audio (cache/file/open). Failures are logged only.
  final Future<void> Function(String soundId)? preloader;

  final SoundboardSessionCache cache = SoundboardSessionCache();

  /// Receives non-fatal errors; defaults to ignore (production passes a
  /// logger). Never throws to callers.
  final SoundboardErrorSink onError;

  StreamSubscription? _incomingSub;
  StreamSubscription? _catalogSub;

  /// Latency instrumentation: click->play and send->receive samples (ms).
  final List<int> localPlayLatenciesMs = [];
  final List<int> remoteReceiveLatenciesMs = [];
  int _lastSendMs = 0;

  SoundboardSession({
    required this.catalog,
    required this.engine,
    required this.transport,
    required this.selfUserId,
    this.durationOf,
    this.preloader,
    SoundboardErrorSink? onError,
  }) : onError = onError ?? ((_, __, ___) {});

  Future<void> init() async {
    _incomingSub = transport.incoming.listen(_onIncoming);
    _catalogSub = catalog.onChanged.listen((_) {
      // Opportunistic: preload newly added sounds while in call.
      preloadAll();
    });
    // Everyone already in the call answers with theirs, so each side knows
    // the other's clock before the first sound (see SoundboardClocks).
    _sendClock(wantsReply: true);
    await preloadAll();
  }

  /// When each sender was last answered, so a burst of clock messages from
  /// someone rejoining gets one reply, not one each.
  final Map<String, int> _clockRepliedAt = {};
  static const _clockReplyInterval = Duration(seconds: 5);

  Future<void> _sendClock({required bool wantsReply}) async {
    try {
      await transport.send(SoundboardEvent.clock(
        senderId: selfUserId,
        eventId: const Uuid().v4(),
        timestampMs: engine.nowMs(),
        wantsReply: wantsReply,
      ));
    } catch (e, s) {
      onError(e, s, 'Soundboard clock send failed');
    }
  }

  void _onClock(SoundboardEvent event, String? authenticatedSenderId) {
    final sender = (authenticatedSenderId?.isNotEmpty == true)
        ? authenticatedSenderId!
        : event.senderId;
    if (sender.isEmpty || sender == selfUserId) return;
    final now = engine.nowMs();
    engine.clocks.observe(sender, event.timestampMs, now);

    if (!event.wantsReply) return;
    final last = _clockRepliedAt[sender];
    if (last != null && now - last < _clockReplyInterval.inMilliseconds) {
      return;
    }
    _clockRepliedAt[sender] = now;
    _sendClock(wantsReply: false);
  }

  Future<void> preloadAll() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final sound in catalog.sounds) {
      if (cache.isLoaded(sound.soundId)) continue;
      try {
        await preloader?.call(sound.soundId);
        cache.markLoaded(sound.soundId, now);
      } catch (e, s) {
        onError(e, s, 'Soundboard preload failed: ${sound.soundId}');
      }
    }
  }

  /// UI click path. Returns instantly after starting local playback.
  Future<void> trigger(String soundId) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final event = engine.localTrigger(
      soundId: soundId,
      senderId: selfUserId,
      eventId: const Uuid().v4(),
      soundDurationMs: durationOf?.call(soundId),
    );
    localPlayLatenciesMs.add(DateTime.now().millisecondsSinceEpoch - t0);
    _lastSendMs = DateTime.now().millisecondsSinceEpoch;
    try {
      await transport.send(event);
    } catch (e, s) {
      // Discreet: ignore, local playback already happened.
      onError(e, s, 'Soundboard send failed');
    }
  }

  Future<void> _onIncoming(TransportIncoming msg) async {
    if (msg.event.isClock) {
      _onClock(msg.event, msg.authenticatedSenderId);
      return;
    }
    final receiveMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastSendMs != 0) {
      remoteReceiveLatenciesMs.add(receiveMs - _lastSendMs);
    }
    // Unknown soundId (removed/old client): ignore, never crash.
    if (catalog.getById(msg.event.soundId) == null) return;
    await engine.onRemoteEvent(
      msg.event,
      authenticatedSenderId: msg.authenticatedSenderId,
      soundDurationMs: durationOf?.call(msg.event.soundId),
    );
  }

  Future<void> setVolume(double volume) async {
    engine.setVolume(volume);
  }

  Future<void> dispose() async {
    await _incomingSub?.cancel();
    await _catalogSub?.cancel();
    await engine.dispose();
    await transport.dispose();
    cache.clear();
  }
}
