import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_tab.dart';
import 'package:commet/ui/pages/settings/categories/room/appearence/room_appearence_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
