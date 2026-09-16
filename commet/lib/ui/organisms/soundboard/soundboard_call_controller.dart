// Wires catalog + engine + transport for one joined call.
//
// Resolution: the VoIP room may belong to several Spaces; every parent
// Space with a soundboard contributes its sounds (one popover section and
// rail entry each). If none has one, the button still renders but the
// popover shows the empty state.
//
// One controller lives per call session, shared by the call view and the
// sidebar "voice connected" panel through [acquire]/[release], so remote
// sounds keep playing while the user looks at another room.
import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/soundboard/entrance_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/matrix/components/soundboard/livekit_soundboard_transport.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_soundboard_emoji_image.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_todevice_soundboard_transport.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_player_factory.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_favorites.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_overlay_registry.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_popover.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class SoundboardCallController extends ChangeNotifier {
  static final Map<VoipSession, SoundboardCallController> _bySession = {};

  /// Returns the controller for [session], creating and initializing it on
  /// first use. Every call must be paired with [release].
  static SoundboardCallController acquire(VoipSession session) {
    final ctrl = _bySession.putIfAbsent(session, () {
      final created = SoundboardCallController(session);
      created.init().catchError((Object e, StackTrace s) =>
          Log.onError(e, s, content: 'Soundboard init failed'));
      return created;
    });
    ctrl._refs++;
    return ctrl;
  }

  void release() {
    if (--_refs > 0) return;
    _bySession.remove(session);
    dispose();
  }

  final VoipSession session;
  SoundboardSession? soundboard;
  SoundboardCatalog catalog = InMemorySoundboardCatalog();
  List<SoundboardSource> sources = const [];

  SoundboardPlayer? _player;

  /// Shared by every call so all open popovers see the same favorites.
  static final SoundboardFavorites favorites =
      SoundboardFavorites.preference(preferences.soundboardFavorites);

  int _refs = 0;
  bool _disposed = false;
  StreamSubscription? _engineSub;

  /// Activations whose overlay has already been shown.
  final Set<String> _shownEventIds = {};

  SoundboardCallController(this.session);

  Future<void> init() async {
    _resolveCatalog();
    // Decide before preloading: the user may leave the room while the catalog
    // downloads, and a late entrance sound would be wrong.
    final entranceSoundId = _claimEntranceSound();
    late final SoundboardEngine engine;
    final player = _player = createSoundboardPlayer(
      resolveSound: (id) => catalog.getById(id),
      resolvePlayableUri: _resolvePlayableUri,
      loadBytes: _loadBytes,
      // Audio completion, not the overlay timer, ends an activation.
      onInstanceFinished: (id) => engine.onAudioCompleted(id),
    );
    engine = SoundboardEngine(player: player);
    // Bridge engine activations -> avatar overlays (sender-specific).
    engine.addListener(_syncOverlays);
    _engineSub = null; // engine uses sync listeners, not streams.

    final transport = _createTransport();
    final sb = SoundboardSession(
      catalog: catalog,
      engine: engine,
      transport: transport,
      selfUserId: session.client.self?.identifier ?? '',
      durationOf: (id) => catalog.getById(id)?.durationMs,
      preloader: _preload,
      onError: (e, s, ctx) => Log.onError(e, s, content: 'Soundboard: $ctx'),
    );
    soundboard = sb;
    engine.setVolume(userVolume);
    // init() subscribes synchronously, then preloads the whole catalog; the
    // entrance sound doesn't wait for that (the player fetches it on demand).
    final initialized = sb.init();
    if (entranceSoundId != null) sb.trigger(entranceSoundId);
    await initialized;
    if (_disposed) return;
    notifyListeners();
  }

  SoundId? _claimEntranceSound() {
    // Voice channels only, not 1:1 calls. The LiveKit room is already
    // connected: the backend awaits connect() before returning the session.
    final room = session.client.getRoom(session.roomId);
    if (room?.getComponent<VoipRoomComponent>() == null) return null;
    if (session.state != VoipState.connected) return null;
    if (!EntranceSoundGate.instance.claim(session, roomId: session.roomId)) {
      return null;
    }
    return pickEntranceSound(
      choice: EntranceSoundChoice(
        soundId: preferences.soundboardEntranceSoundId.value,
        spaceId: preferences.soundboardEntranceSpaceId.value,
      ),
      roomSpaceIds: sources.map((s) => s.id),
      catalog: catalog,
      // Deafening before joining only sets fakeDeafenToggle.
      deafened: session.isDeafened ||
          clientManager?.callManager.fakeDeafenToggle == true,
    );
  }

  void _resolveCatalog() {
    try {
      final roomId = session.roomId;
      sources = [
        for (final space in session.client.spaces)
          if (space.containsRoom(roomId))
            if (space.getComponent<SpaceSoundboardComponent>() case final comp?)
              SoundboardSource(
                id: space.identifier,
                name: space.displayName,
                avatar: space.avatar,
                color: space.color,
                catalog: _CatalogAdapter(comp),
              ),
      ];
      catalog = _CompositeCatalog([for (final s in sources) s.catalog]);
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard: could not resolve catalogs');
    }
  }

  SoundboardTransport _createTransport() {
    // Prefer LiveKit data channel when the session exposes a livekit room.
    final lkRoom = _livekitRoomOf(session);
    if (lkRoom != null) {
      return LivekitSoundboardTransport(lkRoom);
    }
    final mxc = (session.client is MatrixClient)
        ? (session.client as MatrixClient).getMatrixClient()
        : null;
    if (mxc != null) {
      return MatrixToDeviceSoundboardTransport(mxc, roomId: session.roomId);
    }
    return InMemorySoundboardTransport('fallback');
  }

  lk.Room? _livekitRoomOf(VoipSession s) {
    // Avoid a hard import of MatrixLivekitVoipSession (keeps this file
    // testable); duck-type via dynamic.
    try {
      final dyn = s as dynamic;
      final r = dyn.livekitRoom;
      if (r is lk.Room) return r;
    } catch (_) {}
    return null;
  }

  Future<String> _resolvePlayableUri(SoundboardSound sound) =>
      resolvePlayableUri(session.client, sound);

  /// Resolves mxc:// to a local cached file (fast replay, no per-click
  /// download). MxcFileProvider handles cache + authenticated fetch.
  /// media_kit cannot open mxc:// itself, so there is nothing to fall back to.
  static Future<String> resolvePlayableUri(
      Client client, SoundboardSound sound) async {
    final uri = Uri.parse(sound.mediaUri);
    if (client is! MatrixClient || uri.scheme != 'mxc') {
      throw StateError('Cannot play ${sound.mediaUri}');
    }
    final resolved =
        await MxcFileProviderShim(client.getMatrixClient(), uri).resolve();
    if (resolved == null) {
      throw StateError('Could not cache ${sound.mediaUri} for playback');
    }
    return resolved.toString();
  }

  Future<Uint8List> _loadBytes(SoundboardSound sound) =>
      loadBytes(session.client, sound);

  /// Web: the browser has no file cache, so the player keeps the bytes.
  static Future<Uint8List> loadBytes(
      Client client, SoundboardSound sound) async {
    final uri = Uri.parse(sound.mediaUri);
    if (client is! MatrixClient || uri.scheme != 'mxc') {
      throw StateError('Cannot play ${sound.mediaUri}');
    }
    final bytes =
        await MxcFileProvider(client.getMatrixClient(), uri).getFileData();
    if (bytes == null) {
      throw StateError('Could not download ${sound.mediaUri}');
    }
    return bytes;
  }

  Future<void> _preload(String soundId) async {
    // Fill the file cache (web: the player's decoded buffers) so
    // click->play has no download. Failures reach
    // SoundboardSession.preloadAll, which logs them and leaves the sound
    // unmarked so the next preload tries again.
    final player = _player;
    if (player is PreloadingSoundboardPlayer) {
      await player.preload(soundId);
      return;
    }
    final sound = catalog.getById(soundId);
    if (sound == null) return;
    await _resolvePlayableUri(sound);
  }

  void _syncOverlays() {
    if (_disposed) return;
    final engine = soundboard?.engine;
    if (engine == null) return;
    _shownEventIds.retainAll(engine.active.keys);
    for (final entry in engine.active.values) {
      if (!_shownEventIds.add(entry.eventId)) continue;
      final sound = catalog.getById(entry.soundId);
      if (sound == null) continue;
      final shown = SoundboardOverlayRegistry.instance.show(
        userId: entry.senderId,
        soundId: entry.soundId,
        emoji: sound.emoji,
        image: soundboardEmojiImage(sound.emoji, session.client),
        overlayMs: entry.overlayMs,
      );
      // Auto-clear after overlay window so tiles don't stick. A newer
      // trigger by the same sender keeps its own overlay.
      Future.delayed(Duration(milliseconds: entry.overlayMs + 250), () {
        SoundboardOverlayRegistry.instance.clearEntry(entry.senderId, shown);
      });
    }
    notifyListeners();
  }

  Future<void> setVolume01(double v) async {
    await preferences.soundboardVolume.set(v * 100.0);
    soundboard?.engine.setVolume(v.clamp(0.0, 1.5));
    notifyListeners();
  }

  /// Listener's soundboard volume as the engine takes it (0..1.5).
  static double get userVolume =>
      (preferences.soundboardVolume.value / 100.0).clamp(0.0, 1.5);

  double get volume01 =>
      (preferences.soundboardVolume.value / 100.0).clamp(0.0, 1.0);

  @override
  void dispose() {
    _disposed = true;
    _engineSub?.cancel();
    soundboard?.dispose();
    final catalog = this.catalog;
    if (catalog is _CompositeCatalog) catalog.dispose();
    soundboard = null;
    SoundboardOverlayRegistry.instance.clearAll();
    super.dispose();
  }
}

/// Adapts SpaceSoundboardComponent (CRUD) to the read-only catalog seam.
class _CatalogAdapter implements SoundboardCatalog {
  final SpaceSoundboardComponent _inner;
  _CatalogAdapter(this._inner);

  @override
  List<SoundboardSound> get sounds => List<SoundboardSound>.from(_inner.sounds);

  @override
  SoundboardSound? getById(String soundId) => _inner.getById(soundId);

  @override
  Stream<void> get onChanged => _inner.onChanged;
}

/// All Spaces' catalogs seen as one, so remote events resolve a sound from
/// any Space the room belongs to. Sound ids are uuids, unique across Spaces.
class _CompositeCatalog implements SoundboardCatalog {
  final List<SoundboardCatalog> _parts;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late final List<StreamSubscription> _subs;

  _CompositeCatalog(this._parts) {
    _subs = [for (final part in _parts) part.onChanged.listen(_changes.add)];
  }

  @override
  List<SoundboardSound> get sounds {
    final seen = <String>{};
    return [
      for (final part in _parts)
        for (final sound in part.sounds)
          if (seen.add(sound.soundId)) sound,
    ];
  }

  @override
  SoundboardSound? getById(String soundId) {
    for (final part in _parts) {
      final sound = part.getById(soundId);
      if (sound != null) return sound;
    }
    return null;
  }

  @override
  Stream<void> get onChanged => _changes.stream;

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _changes.close();
  }
}

/// Thin shim so the controller compiles without importing the full
/// FileProvider graph in tests (same behavior as MxcFileProvider).
class MxcFileProviderShim {
  final dynamic mx;
  final Uri uri;
  MxcFileProviderShim(this.mx, this.uri);

  Future<Uri?> resolve() async {
    final provider = MxcFileProvider(mx, uri);
    return provider.resolve();
  }
}
