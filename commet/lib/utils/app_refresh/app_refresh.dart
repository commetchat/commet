import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/tasks/client_connection_status_task.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/fatal_error/fatal_error_page.dart';
import 'package:commet/utils/app_refresh/page_reload.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Refreshes the app as a way to get unstuck without closing it.
///
/// On web this reloads the page. Native builds can't reload Dart code, so
/// refreshing leaves any call, disposes the clients, loads the accounts from
/// the database again and rebuilds the widget tree from scratch.
class AppRefresh {
  static String get labelRefreshingApp => Intl.message("Refreshing…",
      desc: "Shown while the app is refreshing itself",
      name: "labelRefreshingApp");

  /// Fires after the client manager has been replaced, for anything that
  /// listens to the old one for the lifetime of the app.
  static final StreamController<void> onRefreshed =
      StreamController.broadcast();

  static bool _refreshing = false;

  static Room? _selectedRoom;

  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    EventBus.onSelectedRoomChanged.stream
        .listen((room) => _selectedRoom = room);

    // Ctrl+R already reloads the page in a browser.
    if (!BuildConfig.WEB) {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
    }
  }

  static bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyR) {
      return false;
    }

    final keyboard = HardwareKeyboard.instance;
    final modifierPressed = defaultTargetPlatform == TargetPlatform.macOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;

    if (!modifierPressed || keyboard.isShiftPressed || keyboard.isAltPressed) {
      return false;
    }

    refresh();
    return true;
  }

  static Future<void> refresh() async {
    if (BuildConfig.WEB) {
      reloadPage();
      return;
    }

    final oldManager = clientManager;
    if (_refreshing || oldManager == null) return;
    _refreshing = true;

    Log.i("Refreshing app");

    try {
      final room = _selectedRoom;
      final theme = await preferences.resolveTheme();

      // Replacing the root drops the whole tree, including the navigator and
      // any open call view, before the clients it uses go away.
      runApp(_RefreshingView(theme: theme));
      await WidgetsBinding.instance.endOfFrame;

      await _leaveCalls(oldManager);
      await oldManager.close();
      _removeConnectionTasks();

      clientManager = await ClientManager.init();
      NeedsPostLoginInit.doPostLoginInit();
      onRefreshed.add(null);

      runApp(App(
        clientManager: clientManager!,
        initialTheme: theme,
        initialClientId: room?.client.identifier,
        initialRoom: room?.identifier,
      ));
    } catch (error, stacktrace) {
      Log.onError(error, stacktrace, content: "Failed to refresh the app");
      runApp(FatalErrorPage(error, stacktrace));
    } finally {
      _refreshing = false;
    }
  }

  /// Leaves every call first so no membership is left behind in the room.
  static Future<void> _leaveCalls(ClientManager manager) async {
    final callManager = manager.callManager;

    await Future.wait(callManager.currentSessions.toList().map((session) async {
      try {
        final leave = session.state == VoipState.incoming
            ? session.declineCall()
            : session.hangUpCall();
        await leave.timeout(const Duration(seconds: 5));
      } catch (error, stacktrace) {
        Log.onError(error, stacktrace,
            content: "Failed to leave call before refreshing");
      }
    }));

    callManager.stopRingtone();
  }

  /// Connection tasks watch the old clients, which will never report again.
  static void _removeConnectionTasks() {
    for (final task in backgroundTaskManager.tasks
        .whereType<ClientConnectionStatusTask>()
        .toList()) {
      backgroundTaskManager.removeTask(task);
    }
  }
}

class _RefreshingView extends StatelessWidget {
  const _RefreshingView({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              const CircularProgressIndicator(),
              Text(AppRefresh.labelRefreshingApp),
            ],
          ),
        ),
      ),
    );
  }
}
