import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';

import 'space_appearence_settings_page.dart';

class SettingsCategorySpace implements SettingsCategory {
  SettingsCategorySpace(this.space);
  Space space;

  @override
  List<SettingsTab> get tabs => List.from([
        if (shouldShowAppearanceSettings())
          SettingsTab(
              label: "Appearance",
              icon: Icons.style,
              pageBuilder: (context) {
                return SpaceAppearanceSettingsPage(
                  space: space,
                );
              }),
      ]);

  @override
  String get title => "Space Settings";

  bool shouldShowAppearanceSettings() {
    return space.permissions.canEditAvatar || space.permissions.canEditName;
  }
}
