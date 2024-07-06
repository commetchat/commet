import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/developer/room_developer_settings_view.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/general/room_general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/room/permissions/matrix/matrix_room_permissions_page.dart';
import 'package:commet/ui/pages/settings/categories/room/security/room_security_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettingsCategoryRoom implements SettingsCategory {
  SettingsCategoryRoom(this.room);
  Room room;

  String get labelRoomSettingsGeneral => Intl.message("General",
      name: "labelRoomSettingsGeneral",
      desc: "Label for general room settings");

  String get labelRoomSettingsAppearance => Intl.message("Appearance",
      name: "labelRoomSettingsAppearance",
      desc: "Label for room appearance settings");

  String get labelRoomSettingsSecurity => Intl.message("Security",
      name: "labelRoomSettingsSecurity",
      desc: "Label for room security settings");

  String get labelRoomSettingsEmoticons => Intl.message("Emoticons",
      name: "labelRoomSettingsEmoticons",
      desc: "Label for room Emoticon settings");

  String get labelRoomSettingsDeveloper => Intl.message("Developer",
      name: "labelRoomSettingsDeveloper",
      desc: "Label for room developer settings");

  String get labelRoomSettingsCategory => Intl.message("Room Settings",
      name: "labelRoomSettingsCategory",
      desc: "Label for the overall settings category of a room");

  String get labelRoomSettingsPermissions => Intl.message("Permissions",
      name: "labelRoomSettingsPermissions",
      desc: "Label for room permission settings");

  @override
  String get title => labelRoomSettingsCategory;

  @override
  List<SettingsTab> get tabs => getTabs();

  List<SettingsTab> getTabs() {
    RoomEmoticonComponent? emoticons =
        room.getComponent<RoomEmoticonComponent>();
    return List.from([
      SettingsTab(
        label: labelRoomSettingsGeneral,
        icon: Icons.settings,
        pageBuilder: (context) {
          return RoomGeneralSettingsPage(
            room: room,
          );
        },
      ),
      if (room.permissions.canEditAppearance)
        SettingsTab(
            label: labelRoomSettingsAppearance,
            icon: Icons.style,
            pageBuilder: (context) {
              return RoomAppearanceSettingsPage(
                room: room,
              );
            }),
      if (room.permissions.canEditRoomSecurity)
        SettingsTab(
            label: labelRoomSettingsSecurity,
            icon: Icons.lock,
            pageBuilder: (context) {
              return RoomSecuritySettingsPage(
                room: room,
              );
            }),
      if (emoticons != null &&
          (room.permissions.canEditRoomEmoticons ||
              emoticons.ownedPacks.isNotEmpty))
        SettingsTab(
            label: labelRoomSettingsEmoticons,
            icon: Icons.emoji_emotions,
            pageBuilder: (context) {
              return RoomEmojiPackSettingsPage(room);
            }),
      if (room is MatrixRoom)
        SettingsTab(
            label: labelRoomSettingsPermissions,
            icon: Icons.admin_panel_settings,
            makeScrollable: false,
            pageBuilder: (context) {
              return MatrixRoomPermissionsPage((room as MatrixRoom).matrixRoom);
            }),
      if (preferences.developerMode)
        SettingsTab(
            label: labelRoomSettingsDeveloper,
            icon: Icons.code,
            pageBuilder: (context) {
              return RoomDeveloperSettingsView(room);
            }),
    ]);
  }
}
