import 'package:commet/client/client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/developer/room_developer_settings_view.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/general/room_general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/security/room_security_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';

class SettingsCategoryRoom implements SettingsCategory {
  SettingsCategoryRoom(this.room);
  Room room;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
          label: T.current.settingsGeneral,
          icon: Icons.settings,
          pageBuilder: (context) {
            return RoomGeneralSettingsPage(
              room: room,
            );
          },
        ),
        if (room.permissions.canEditAppearance)
          SettingsTab(
              label: T.current.roomSettingsAppearance,
              icon: Icons.style,
              pageBuilder: (context) {
                return RoomAppearanceSettingsPage(
                  room: room,
                );
              }),
        if (room.permissions.canEditRoomSecurity)
          SettingsTab(
              label: T.current.settingsGeneral,
              icon: Icons.lock,
              pageBuilder: (context) {
                return RoomSecuritySettingsPage(
                  room: room,
                );
              }),
        if (room.permissions.canEditRoomEmoticons ||
            room.roomEmoticons!.ownedPacks.isNotEmpty)
          SettingsTab(
              label: T.current.settingsEmoji,
              icon: Icons.emoji_emotions,
              pageBuilder: (context) {
                return RoomEmojiPackSettingsPage(room);
              }),
        if (preferences.developerMode)
          SettingsTab(
              label: T.current.settingsDeveloper,
              icon: Icons.code,
              pageBuilder: (context) {
                return RoomDeveloperSettingsView(room.developerInfo);
              }),
      ]);

  @override
  String get title => T.current.roomSettingsHeader;
}
