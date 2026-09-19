// One DJ booth per LiveKit call, alive as long as the call: the DJ's music
// must keep playing while they look at another room. The call session opens
// it when it starts and closes it on hang up; the UI finds it with [of].
import 'dart:async';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/dj/livekit_dj_transport.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/dj/dj_booth_panel.dart' show liveDjMusicVolume;
import 'package:commet/ui/organisms/dj/dj_toast.dart';
import 'package:commet/ui/organisms/dj/dj_tools_prompt.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class DjBooths {
  static final Map<VoipSession, DjSession> _booths = {};
  static final Map<VoipSession, List<StreamSubscription>> _subs = {};
  static final Map<VoipSession, VoidCallback> _monitorListeners = {};

  /// Fires when a booth opens or closes.
  static final StreamController<void> _changed = StreamController.broadcast();
  static Stream<void> get onChanged => _changed.stream;

  static DjSession? of(VoipSession? session) =>
      session == null ? null : _booths[session];

  static DjSession open(VoipSession session, lk.Room room) {
    final existing = _booths[session];
    if (existing != null) return existing;
    final platform = DjPlatform.instance;
    final dj = DjSession(
      transport: LivekitDjTransport(room),
      caps: DjCaps(canDj: platform.canDj, platform: platform.name),
      selfUserId: session.client.self?.identifier ?? '',
      engineFactory: platform.engineFactory(room),
      resolver: platform.resolver,
      prepareToDj: platform.canDj ? ensureDjTools : null,
      acceptPass: platform.canDj
          ? (from) => askToTakeDecks(session.client
                  .getRoom(session.roomId)
                  ?.getMemberOrFallback(djUserIdOf(from))
                  .displayName ??
              djUserIdOf(from))
          : null,
    )..start();
    _booths[session] = dj;

    // The DJ hears their own music at their music volume, and not at all
    // while deafened, like everyone else's.
    void applyMonitor() => dj.monitorVolume = session.isDeafened
        ? 0
        : liveDjMusicVolume.value ?? preferences.djMusicVolume.value;
    liveDjMusicVolume.addListener(applyMonitor);
    _monitorListeners[session] = applyMonitor;
    // The level is one for all music: a change made in another call's booth
    // applies to this call's music too.
    void applyListening() {
      if (session.isDeafened) return;
      for (final stream in session.streams.whereType<MatrixLivekitVoipStream>()) {
        if (stream.type == VoipStreamType.music &&
            stream.direction == VoipStreamDirection.incoming) {
          stream.applyVolume(preferences.djMusicVolume.value);
        }
      }
    }

    _subs[session] = [
      preferences.djMusicVolume.onChanged.listen((_) {
        applyMonitor();
        applyListening();
      }),
      session.onStateChanged.listen((_) => applyMonitor()),
      dj.notices.listen(_showNotice),
    ];
    dj.addListener(applyMonitor);
    _changed.add(null);
    return dj;
  }

  /// Wherever the user is: a handoff that failed matters most to someone who
  /// never opened the booth.
  static void _showNotice(DjNotice notice) {
    Log.i('DJ booth: $notice');
    DjToast.show(notice.message, isError: notice.isError);
  }

  static Future<void> close(VoipSession session) async {
    final dj = _booths.remove(session);
    for (final sub in _subs.remove(session) ?? const <StreamSubscription>[]) {
      await sub.cancel();
    }
    final monitor = _monitorListeners.remove(session);
    if (monitor != null) {
      liveDjMusicVolume.removeListener(monitor);
      dj?.removeListener(monitor);
    }
    if (dj == null) return;
    _changed.add(null);
    try {
      await dj.dispose();
      await dj.transport.dispose();
    } catch (e, s) {
      Log.onError(e, s, content: 'DJ booth: could not close');
    }
  }
}
