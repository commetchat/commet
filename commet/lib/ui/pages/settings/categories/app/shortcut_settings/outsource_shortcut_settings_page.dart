import 'dart:io';

import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class OutsourceShortcutSettingsPage extends StatelessWidget {
  const OutsourceShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      mode: TileType.surfaceContainerLow,
      header: "Configure Shortcuts",
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tiamat.Text(
              "In your current environment, keyboard shortcuts must be configured in your system settings."),
          tiamat.Button(
            text: "Open Settings",
            onTap: openSystemSettings,
          )
        ],
      ),
    );
  }

  openSystemSettings() {
    if (PlatformUtils.isDesktopEnvironment(DesktopEnvironment.KDEPlasma)) {
      if (BuildConfig.IS_FLATPAK) {
        Process.start("flatpak-spawn", ["--host" "systemsettings" "kcm_keys"]);
      } else {
        Process.start("systemsettings", ["kcm_keys"]);
      }
    }
  }
}
