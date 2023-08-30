import 'package:commet/client/client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/room/developer/room_developer_settings_view.dart';
import 'package:commet/ui/pages/settings/categories/space/space_emoji_pack_settings.dart';
import 'package:commet/ui/pages/settings/categories/space/space_general_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'space_appearance_settings_page.dart';

class SettingsCategorySpace implements SettingsCategory {
  SettingsCategorySpace(this.space);
  Space space;

  String get labelSpaceSettingsGeneral =>
      Intl.message("General", desc: "Label for general space settings");

  String get labelSpaceAppearanceSettings =>
      Intl.message("Appearance", desc: "Label for space appearance settings");

  String get labelSpaceEmoticonSettings =>
      Intl.message("Emoticons", desc: "Label for space emoticon settings");

  String get labelSpaceDeveloperSettings =>
      Intl.message("Developer", desc: "Label for space developer settings");

  String get labelSettingsCategorySpace => Intl.message("Space Settings",
      desc: "Label for the overall space settings category");

  @override
  String get title => labelSettingsCategorySpace;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: labelSpaceSettingsGeneral,
            icon: Icons.settings,
            pageBuilder: (context) {
              return SpaceGeneralSettingsPage(
                space: space,
              );
            }),
        if (shouldShowAppearanceSettings())
          SettingsTab(
              label: labelSpaceAppearanceSettings,
              icon: Icons.style,
              pageBuilder: (context) {
                return SpaceAppearanceSettingsPage(
                  space: space,
                );
              }),
        if ((space.permissions.canEditRoomEmoticons ||
                space.emoticons!.ownedPacks.isNotEmpty) &&
            space.emoticons != null)
          SettingsTab(
              label: labelSpaceEmoticonSettings,
              icon: Icons.emoji_emotions,
              pageBuilder: (context) {
                return SpaceEmojiPackSettings(space);
              }),
        if (preferences.developerMode)
          SettingsTab(
            label: labelSpaceDeveloperSettings,
            icon: Icons.code,
            pageBuilder: (context) {
              return RoomDeveloperSettingsView(space.developerInfo);
            },
          ),
      ]);

  bool shouldShowAppearanceSettings() {
    return space.permissions.canEditAvatar || space.permissions.canEditName;
  }
}
