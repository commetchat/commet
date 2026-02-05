import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/pages/settings/categories/app/shortcut_settings/keyboard_hook_shortcuts_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/shortcut_settings/outsource_shortcut_settings_page.dart';
import 'package:flutter/material.dart';

class ShortcutSettingsPage extends StatelessWidget {
  const ShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktopEnvironment(DesktopEnvironment.KDEPlasma)) {
      return OutsourceShortcutSettingsPage();
    }

    return KeyboardHookShortcutsSettingsPage();
  }
}
