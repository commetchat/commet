import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts_linux.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:intl/intl.dart';

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

  static String get shortcutNameMute => Intl.message("Mute",
      name: "shortcutNameMute",
      desc: "name for the system wide shortcut to activate microphone mute");

  static String get shortcutNameUnmute => Intl.message("Unmute",
      name: "shortcutNameUnmute",
      desc: "name for the system wide shortcut to disable microphone mute");

  static String get shortcutNameToggleMute => Intl.message("Toggle Mute",
      name: "shortcutNameToggleMute",
      desc:
          "name for the system wide shortcut to toggle the microphone mute status");

  static Map<String, AppShortcut> shortcuts = {
    "mute": AppShortcut(
        getDisplayName: () => shortcutNameMute,
        callback: () => clientManager?.callManager.mute()),
    "unmute": AppShortcut(
        getDisplayName: () => shortcutNameUnmute,
        callback: () => clientManager?.callManager.unmute()),
    "toggle_mute": AppShortcut(
        getDisplayName: () => shortcutNameToggleMute,
        callback: () => clientManager?.callManager.toggleMute()),
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
