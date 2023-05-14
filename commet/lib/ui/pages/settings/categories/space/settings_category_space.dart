import 'package:commet/client/client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/categories/space/space_general_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';

import 'space_appearance_settings_page.dart';

class SettingsCategorySpace implements SettingsCategory {
  SettingsCategorySpace(this.space);
  Space space;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: "General",
            icon: Icons.settings,
            pageBuilder: (context) {
              return SpaceGeneralSettingsPage(
                space: space,
              );
            }),
        if (shouldShowAppearanceSettings())
          SettingsTab(
              label: T.current.spaceSettingsSpaceAppearance,
              icon: Icons.style,
              pageBuilder: (context) {
                return SpaceAppearanceSettingsPage(
                  space: space,
                );
              }),
      ]);

  @override
  String get title => T.current.spaceSettingsHeader;

  bool shouldShowAppearanceSettings() {
    return space.permissions.canEditAvatar || space.permissions.canEditName;
  }
}
