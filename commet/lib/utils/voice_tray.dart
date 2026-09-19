import 'dart:async';

import 'package:commet/client/call_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/window_management.dart';
import 'package:intl/intl.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

enum VoiceTrayStatus {
  /// Not in a call: the app logo.
  idle,

  /// In a call and heard: a mic.
  live,

  /// In a call, muted or deafened: a crossed-out mic.
  muted,
}

/// The system tray icon, like Discord's: the app logo, or while we are in a
/// voice call a mic showing whether we can be heard. Clicking it (Windows) or
/// its "Open" item (Linux, where a click always opens the menu) brings the
/// window back.
///
/// Windows and Linux only. On Linux it needs an appindicator; a build without
/// one runs with no tray icon (see third_party/tray_manager).
class VoiceTray with TrayListener {
  VoiceTray._();

  static final VoiceTray instance = VoiceTray._();

  static String get labelTrayOpen => Intl.message("Open ${BuildConfig.app}",
      name: "labelTrayOpen",
      desc: "Tray icon menu item that brings the app window back");

  static String get labelTrayQuit => Intl.message("Quit",
      name: "labelTrayQuit", desc: "Tray icon menu item that closes the app");

  static String get labelTrayMute => Intl.message("Mute",
      name: "labelTrayMute",
      desc: "Tray icon menu item that mutes the microphone in a call");

  static String get labelTrayUnmute => Intl.message("Unmute",
      name: "labelTrayUnmute",
      desc: "Tray icon menu item that unmutes the microphone in a call");

  static String get labelTrayDeafen => Intl.message("Deafen",
      name: "labelTrayDeafen",
      desc: "Tray icon menu item that deafens the user in a call");

  static String get labelTrayUndeafen => Intl.message("Undeafen",
      name: "labelTrayUndeafen",
      desc: "Tray icon menu item that undeafens the user in a call");

  static String get tooltipTrayInCall => Intl.message("In a voice channel",
      name: "tooltipTrayInCall",
      desc: "Tray icon tooltip while in a call and not muted");

  static String get tooltipTrayMuted => Intl.message("Muted",
      name: "tooltipTrayMuted",
      desc: "Tray icon tooltip while in a call and muted or deafened");

  static const _open = "open";
  static const _quit = "quit";
  static const _mute = "mute";
  static const _deafen = "deafen";

  static bool get supported => PlatformUtils.isWindows || PlatformUtils.isLinux;

  /// What the icon shows for [sessions]: muted only when every call we are
  /// in has us muted or deafened.
  static VoiceTrayStatus statusOf(Iterable<VoipSession> sessions) {
    final inCall = sessions.where((session) =>
        session.state == VoipState.connected ||
        session.state == VoipState.connecting ||
        session.state == VoipState.outgoing);
    if (inCall.isEmpty) return VoiceTrayStatus.idle;
    final heard = inCall
        .any((session) => !session.isMicrophoneMuted && !session.isDeafened);
    return heard ? VoiceTrayStatus.live : VoiceTrayStatus.muted;
  }

  bool _started = false;
  bool _available = false;
  VoiceTrayStatus? _shown;
  bool? _shownDeafened;
  CallManager? _watching;
  final List<StreamSubscription> _listSubs = [];
  final List<StreamSubscription> _sessionSubs = [];
  Timer? _poll;

  Future<void> init() async {
    if (!supported || _started) return;
    _started = true;

    trayManager.addListener(this);
    try {
      await _show(VoiceTrayStatus.idle, deafened: false);
    } catch (e) {
      // Linux without an appindicator: no tray, nothing else changes.
      Log.w("No system tray icon: $e");
      trayManager.removeListener(this);
      return;
    }
    _available = true;

    // Mute changes are announced by LiveKit sessions but not by legacy 1:1
    // ones, and an app refresh replaces the call manager: this catches both.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _refresh();
  }

  /// Takes the icon down, so Windows doesn't leave a dead one behind.
  Future<void> dispose() async {
    if (!_available) return;
    _available = false;
    _poll?.cancel();
    for (final sub in [..._listSubs, ..._sessionSubs]) {
      sub.cancel();
    }
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      Log.w("Could not remove the tray icon: $e");
    }
  }

  void _refresh() {
    if (!_available) return;
    final calls = clientManager?.callManager;
    if (!identical(calls, _watching)) _watch(calls);

    final sessions = calls?.currentSessions ?? const <VoipSession>[];
    final status = statusOf(sessions);
    final deafened = calls?.isDeafened ?? false;
    if (status == _shown && deafened == _shownDeafened) return;
    _show(status, deafened: deafened).catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: "Could not update the tray icon");
    });
  }

  void _watch(CallManager? calls) {
    for (final sub in _listSubs) {
      sub.cancel();
    }
    _listSubs.clear();
    _watching = calls;
    if (calls != null) {
      _listSubs.add(calls.currentSessions.onListUpdated.listen((_) {
        _watchSessions();
        _refresh();
      }));
    }
    _watchSessions();
  }

  void _watchSessions() {
    for (final sub in _sessionSubs) {
      sub.cancel();
    }
    _sessionSubs.clear();
    for (final session in _watching?.currentSessions ?? const []) {
      _sessionSubs.add(session.onStateChanged.listen((_) => _refresh()));
    }
  }

  Future<void> _show(VoiceTrayStatus status, {required bool deafened}) async {
    _shown = status;
    _shownDeafened = deafened;

    // Windows loads tray icons from .ico, the appindicator from an image.
    final extension = PlatformUtils.isWindows ? "ico" : "png";
    await trayManager.setIcon("assets/images/tray/${status.name}.$extension");

    final inCall = status != VoiceTrayStatus.idle;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: _open, label: labelTrayOpen),
      if (inCall) ...[
        MenuItem.separator(),
        // Deafened counts as muted: unmuting undeafens too
        // (CallManager.toggleMute).
        MenuItem(
            key: _mute,
            label: status == VoiceTrayStatus.muted
                ? labelTrayUnmute
                : labelTrayMute),
        MenuItem(
            key: _deafen,
            label: deafened ? labelTrayUndeafen : labelTrayDeafen),
      ],
      MenuItem.separator(),
      MenuItem(key: _quit, label: labelTrayQuit),
    ]));

    try {
      await trayManager.setToolTip(switch (status) {
        VoiceTrayStatus.idle => BuildConfig.app,
        VoiceTrayStatus.live => "${BuildConfig.app}: $tooltipTrayInCall",
        VoiceTrayStatus.muted => "${BuildConfig.app}: $tooltipTrayMuted",
      });
    } catch (_) {
      // Appindicators have no tooltips.
    }
  }

  Future<void> _openWindow() async {
    try {
      if (await windowManager.isMinimized()) await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (e, s) {
      Log.onError(e, s, content: "Could not bring the window back");
    }
  }

  // Windows only: on Linux a click opens the menu.
  @override
  void onTrayIconMouseDown() => _openWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final calls = clientManager?.callManager;
    switch (menuItem.key) {
      case _open:
        _openWindow();
      case _mute:
        calls?.toggleMute();
      case _deafen:
        calls?.toggleDeafen();
      case _quit:
        WindowManagement.close();
    }
    _refresh();
  }
}
