import 'package:commet/ui/pages/settings/categories/app/shortcut_settings/keyboard_hook_shortcuts_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class OutsourceShortcutSettingsPage extends StatelessWidget {
  const OutsourceShortcutSettingsPage({super.key});

  String get labelSystemKeyboardShortcutsOutsourceDescription => Intl.message(
        "In your current environment, keyboard shortcuts must be configured in your system settings.",
        name: "labelSystemKeyboardShortcutsOutsourceDescription",
      );

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      mode: TileType.surfaceContainerLow,
      header: KeyboardHookShortcutsSettingsPage.labelConfigureKeyboardShortcuts,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tiamat.Text(
            labelSystemKeyboardShortcutsOutsourceDescription,
          ),
        ],
      ),
    );
  }
}
