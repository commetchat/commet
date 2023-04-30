import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_tab.dart';
import 'package:commet/ui/pages/settings/categories/room/appearence/room_appearence_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsCategoryRoom implements SettingsCategory {
  SettingsCategoryRoom(this.room);
  Room room;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: T.current.settingsTabManageAccounts,
            icon: Icons.person,
            pageBuilder: (context) {
              return RoomAppearanceSettingsPage(
                room: room,
              );
            }),
      ]);

  @override
  String get title => "Room Settings";
}
