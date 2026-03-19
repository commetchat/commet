import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

class WindowManagement {
  static bool _isShuttingDown = false;

  static Future<void> init() async {
    if (!(PlatformUtils.isLinux || PlatformUtils.isWindows)) return;

    await windowManager.ensureInitialized();
    _WindowListener listener = _WindowListener();

    windowManager.setPreventClose(true);
    windowManager.addListener(listener);

    HardwareKeyboard.instance.addHandler(_onKeyEvent);

    EventBus.onSelectedRoomChanged.stream.listen(_onSelectedRoomChanged);
    EventBus.onSelectedSpaceChanged.stream.listen(_onSelectedSpaceChanged);

    _registerProcessSignalHandlers();

    await _initTrayManager();
    TrayManager.instance.addListener(_TrayListener());

    if (commandLineArgs.contains("--minimize")) {
      windowManager.minimize();
    }
  }

  static void _registerProcessSignalHandlers() {
    ProcessSignal.sigint.watch().listen((_) {
      _shutdownApplication();
    });

    ProcessSignal.sigterm.watch().listen((_) {
      _shutdownApplication();
    });
  }

  static Future<void> _shutdownApplication() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;

    if (clientManager != null) {
      for (var client in clientManager!.clients) {
        await client.close();
      }
    }

    exit(0);
  }

  static Future<void> _initTrayManager() async {
    await TrayManager.instance.setIcon('assets/images/app_icon/app_icon_rounded.png');
    await _setupTrayMenu();
  }

  static Future<void> _setupTrayMenu() async {
    final menu = [
      MenuItem(label: 'Commet', key: 'app_name', disabled: true),
      MenuItem.separator(),
      MenuItem(label: 'Open Commet', key: 'show'),
      MenuItem(label: 'Quit Commet', key: 'close'),
    ];
    await TrayManager.instance.setContextMenu(Menu(items: menu));
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
      windowManager.hide();
    } else {
      await WindowManagement._shutdownApplication();
    }
  }
}

class _TrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    _showWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'close':
        _closeApplication();
        break;
    }
  }

  Future<void> _showWindow() async {
    if (await windowManager.isVisible()) {
      await windowManager.focus();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  Future<void> _closeApplication() async {
    await WindowManagement._shutdownApplication();
  }
}
