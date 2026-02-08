import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagement {
  static Future<void> init() async {
    if (!BuildConfig.DESKTOP) return;

    await windowManager.ensureInitialized();
    _WindowListener listener = _WindowListener();

    windowManager.setPreventClose(true);
    windowManager.addListener(listener);

    if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
      EventBus.onSelectedRoomChanged.stream.listen(_onSelectedRoomChanged);
      EventBus.onSelectedSpaceChanged.stream.listen(_onSelectedSpaceChanged);

      await windowManager.show();

      if (commandLineArgs.contains("--minimize")) {
        windowManager.minimize();
      }
    }
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
    final result = [_currentRoomName, _currentSpaceName, "commet"]
        .whereNot((a) => a == null)
        .join(" | ");
    windowManager.setTitle(result);
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    super.onWindowClose();

    if (preferences.minimizeOnClose) {
      windowManager.minimize();
    } else {
      if (clientManager != null) {
        for (var client in clientManager!.clients) {
          await client.close();
        }
      }

      exit(0);
    }
  }
}
