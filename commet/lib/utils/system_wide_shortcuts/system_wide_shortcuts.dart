import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts_linux.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class SystemWideShortcuts {
  static void init() async {
    if (PlatformUtils.isLinux) {
      SystemWideShortcutsLinux.init();
    }

    for (var shortcut in shortcuts.entries) {
      var hotkey = preferences.getSystemHotkey(shortcut.key);
      if (hotkey != null) {
        await shortcut.value.setHotkey(hotkey);
      }
    }
  }

  static bool get isSupported {
    if (PlatformUtils.isWindows) return true;

    if (PlatformUtils.isDisplayServer(DisplayServer.X11)) {
      return true;
    }

    if (PlatformUtils.isDesktopEnvironment(DesktopEnvironment.KDEPlasma)) {
      return true;
    }

    return false;
  }

  static Map<String, AppShortcut> shortcuts = {
    "mute": AppShortcut(
        getDisplayName: () => "Mute",
        callback: () => clientManager.callManager.mute()),
    "unmute": AppShortcut(
        getDisplayName: () => "Unmute",
        callback: () => clientManager.callManager.unmute()),
    "toggle_mute": AppShortcut(
        getDisplayName: () => "Toggle Mute",
        callback: () => clientManager.callManager.toggleMute()),
  };

  static Future<void> storeHotkeys() async {
    for (var i in shortcuts.entries) {
      await preferences.setSystemHotkey(i.key, i.value.hotkey);
    }
  }
}

class AppShortcut {
  void Function() callback;

  String Function() getDisplayName;

  HotKey? hotkey;

  AppShortcut({
    required this.getDisplayName,
    required this.callback,
  });

  Future<void> setHotkey(HotKey newHotkey) async {
    if (hotkey != null) {
      await hotKeyManager.unregister(hotkey!);
    }

    for (var key in SystemWideShortcuts.shortcuts.values) {
      if (key.hotkey == newHotkey) {
        await key.clearHotkey();
      }
    }

    await hotKeyManager.register(
      newHotkey,
      keyDownHandler: (hotKey) {
        callback();
      },
    );

    hotkey = newHotkey;

    await SystemWideShortcuts.storeHotkeys();
  }

  Future<void> clearHotkey() async {
    if (hotkey != null) {
      hotKeyManager.unregister(hotkey!);
      hotkey = null;
    }

    await SystemWideShortcuts.storeHotkeys();
  }
}
