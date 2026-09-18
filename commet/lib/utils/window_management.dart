import 'package:collection/collection.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagement {
  static bool _closing = false;
  static bool _clientsClosed = false;

  /// Releases the clients and the call manager.
  ///
  /// Bounded like AppRefresh: closing a client awaits the sync transaction in
  /// flight, which may be exactly what is slow. Never throws: a client that
  /// fails to close must not keep the window from closing.
  static Future<void> closeClients() async {
    if (_clientsClosed) return;
    _clientsClosed = true;

    try {
      await clientManager?.close().timeout(const Duration(seconds: 5),
          onTimeout: () => Log.w("Closing clients timed out"));
    } catch (error, stacktrace) {
      Log.onError(error, stacktrace, content: "Failed to release the clients");
    }
  }

  /// Shuts the app down through the window manager.
  ///
  /// Not `exit()`: that skips the engine teardown and crashes on Windows
  /// (coremessaging.dll). `destroy()` posts the platform's quit message, so
  /// the runner's message loop returns and the process tears down normally.
  static Future<void> close() async {
    if (_closing) return;
    _closing = true;

    await closeClients();

    try {
      await windowManager.destroy();
    } catch (error, stacktrace) {
      // Let a later attempt try again rather than wedging the window shut.
      _closing = false;
      Log.onError(error, stacktrace, content: "Failed to close the window");
    }
  }

  static Future<void> init() async {
    if (!(PlatformUtils.isLinux || PlatformUtils.isWindows)) return;

    await windowManager.ensureInitialized();
    _WindowListener listener = _WindowListener();

    windowManager.setPreventClose(true);
    windowManager.addListener(listener);

    HardwareKeyboard.instance.addHandler(_onKeyEvent);

    EventBus.onSelectedRoomChanged.stream.listen(_onSelectedRoomChanged);
    EventBus.onSelectedSpaceChanged.stream.listen(_onSelectedSpaceChanged);

    if (commandLineArgs.contains("--minimize")) {
      windowManager.minimize();
    } else {
      windowManager.show();
      windowManager.focus();
    }
  }

  static bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
      return true;
    }
    return false;
  }

  static void _toggleFullscreen() async {
    var isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }

  static String? _currentSpaceName;
  static String? _currentRoomName;

  static void _onSelectedRoomChanged(Room? event) {
    _currentRoomName = event?.displayName;
    _updateTitle();
  }

  static void _onSelectedSpaceChanged(Space? event) {
    _currentSpaceName = event?.displayName;
    _updateTitle();
  }

  static void _updateTitle() {
    final result = [
      _currentRoomName,
      _currentSpaceName,
      "commet",
    ].whereNot((a) => a == null).join(" | ");
    windowManager.setTitle(result);
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    super.onWindowClose();

    if (preferences.minimizeOnClose.value) {
      windowManager.minimize();
      return;
    }

    await WindowManagement.close();
  }
}
