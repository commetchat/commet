import 'package:commet/client/client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/room/developer/room_developer_settings_view.dart';
import 'package:commet/ui/pages/settings/categories/space/space_emoji_pack_settings.dart';
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
            label: T.current.settingsGeneral,
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
        if (space.permissions.canEditRoomEmoticons ||
            space.emoticons!.ownedPacks.isNotEmpty)
          SettingsTab(
              label: T.current.settingsEmoji,
              icon: Icons.emoji_emotions,
              pageBuilder: (context) {
                return SpaceEmojiPackSettings(space);
              }),
        if (preferences.developerMode)
          SettingsTab(
            label: T.current.settingsDeveloper,
            icon: Icons.code,
            pageBuilder: (context) {
              return RoomDeveloperSettingsView(space.developerInfo);
            },
          ),
      ]);

  @override
  String get title => T.current.spaceSettingsHeader;

  bool shouldShowAppearanceSettings() {
    return space.permissions.canEditAvatar || space.permissions.canEditName;
  }
}
