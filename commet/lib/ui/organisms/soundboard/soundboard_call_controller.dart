// Wires catalog + engine + transport for one joined call.
//
// Resolution: the VoIP room may belong to one or more Spaces; we use the
// first parent Space containing the room (catalog belongs to the Space).
// If no parent Space has a soundboard, the button still renders but the
// panel shows the empty state.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/soundboard/livekit_soundboard_transport.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_todevice_soundboard_transport.dart';
import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_overlay_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class SoundboardCallController extends ChangeNotifier {
  final VoipSession session;
  SoundboardSession? soundboard;
  SoundboardCatalog catalog = InMemorySoundboardCatalog();
  SpaceSoundboardComponent? spaceComponent;

  bool _disposed = false;
  StreamSubscription? _engineSub;

  SoundboardCallController(this.session);

  Future<void> init() async {
    _resolveCatalog();
    final engine = SoundboardEngine(
      player: MediaKitSoundboardPlayer(
        resolveSound: (id) => catalog.getById(id),
        resolvePlayableUri: _resolvePlayableUri,
      ),
    );
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
    await sb.init();
    final v = preferences.soundboardVolume.value / 100.0;
    engine.setVolume(v.clamp(0.0, 1.5));
    notifyListeners();
  }

  void _resolveCatalog() {
    try {
      final client = session.client;
      final roomId = session.roomId;
      for (final space in client.spaces) {
        if (!space.containsRoom(roomId)) continue;
        final comp = space.getComponent<SpaceSoundboardComponent>();
        if (comp != null) {
          spaceComponent = comp;
          catalog = _CatalogAdapter(comp);
          return;
        }
      }
    } catch (_) {}
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

  Future<String> _resolvePlayableUri(SoundboardSound sound) async {
    final mxcUri = sound.mediaUri;
    // Resolve mxc:// to a local cached file (fast replay, no per-click
    // download). MxcFileProvider handles cache + authenticated fetch.
    try {
      final client = session.client;
      if (client is MatrixClient) {
        final mx = client.getMatrixClient();
        final uri = Uri.parse(mxcUri);
        if (uri.scheme == 'mxc') {
          final provider =
              MxcFileProviderShim(mx, uri);
          final resolved = await provider.resolve();
          if (resolved != null) return resolved.toString();
        }
      }
    } catch (_) {}
    return mxcUri;
  }

  Future<void> _preload(String soundId) async {
    // Best-effort: touch the HTTP cache so click->play has no download.
    try {
      final sound = catalog.getById(soundId);
      if (sound == null) return;
      await _resolvePlayableUri(sound);
    } catch (_) {}
  }

  void _syncOverlays() {
    if (_disposed) return;
    final engine = soundboard?.engine;
    if (engine == null) return;
    for (final entry in engine.active.values) {
      final sound = catalog.getById(entry.soundId);
      if (sound == null) continue;
      SoundboardOverlayRegistry.instance.show(
        userId: entry.senderId,
        soundId: entry.soundId,
        emoji: sound.emoji,
        overlayMs: entry.overlayMs,
      );
      // Auto-clear after overlay window so tiles don't stick.
      Future.delayed(Duration(milliseconds: entry.overlayMs + 250), () {
        SoundboardOverlayRegistry.instance.clearUser(entry.senderId);
        engine.markFinished(entry.soundId);
      });
    }
    notifyListeners();
  }

  Future<void> setVolume01(double v) async {
    await preferences.soundboardVolume.set(v * 100.0);
    soundboard?.engine.setVolume(v.clamp(0.0, 1.5));
    notifyListeners();
  }

  double get volume01 =>
      (preferences.soundboardVolume.value / 100.0).clamp(0.0, 1.0);

  @override
  void dispose() {
    _disposed = true;
    _engineSub?.cancel();
    soundboard?.dispose();
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
  List<SoundboardSound> get sounds =>
      List<SoundboardSound>.from(_inner.sounds);

  @override
  SoundboardSound? getById(String soundId) => _inner.getById(soundId);

  @override
  Stream<void> get onChanged => _inner.onChanged;
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
