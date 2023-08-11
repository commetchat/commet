import 'package:commet/client/client.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_page.dart';
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
          label: "General",
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
              label: "Security",
              icon: Icons.lock,
              pageBuilder: (context) {
                return RoomSecuritySettingsPage(
                  room: room,
                );
              }),
      ]);

  @override
  String get title => T.current.roomSettingsHeader;
}
