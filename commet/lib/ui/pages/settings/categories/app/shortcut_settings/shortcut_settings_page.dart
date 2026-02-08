import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/shortcut_settings/keyboard_hook_shortcuts_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/shortcut_settings/outsource_shortcut_settings_page.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts.dart';
import 'package:flutter/material.dart';

class ShortcutSettingsPage extends StatelessWidget {
  const ShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (SystemWideShortcuts.isSupported == false) {
      return Placeholder();
    }

    bool showOutsourceMenu =
        PlatformUtils.isDisplayServer(DisplayServer.Wayland) &&
            PlatformUtils.isDesktopEnvironment(DesktopEnvironment.KDEPlasma);

    bool showHooksMenu = !showOutsourceMenu;

    if (preferences.developerMode) {
      showHooksMenu = true;
    }

    if (BuildConfig.IS_FLATPAK) {
      showHooksMenu = false;
    }

    return Column(
      spacing: 8,
      children: [
        if (showOutsourceMenu) OutsourceShortcutSettingsPage(),
        if (showHooksMenu) KeyboardHookShortcutsSettingsPage()
      ],
    );
  }
}
