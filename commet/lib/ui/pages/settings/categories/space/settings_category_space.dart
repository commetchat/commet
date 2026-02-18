import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/pages/settings/categories/room/permissions/matrix/matrix_room_permissions_page.dart';
import 'package:commet/ui/pages/settings/categories/space/space_developer_settings_view.dart';
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

  String get labelSpaceSettingsGeneral => Intl.message("General",
      name: "labelSpaceSettingsGeneral",
      desc: "Label for general space settings");

  String get labelSpaceAppearanceSettings => Intl.message("Appearance",
      name: "labelSpaceAppearanceSettings",
      desc: "Label for space appearance settings");

  String get labelSpaceEmoticonSettings => Intl.message("Emoticons",
      name: "labelSpaceEmoticonSettings",
      desc: "Label for space emoticon settings");

  String get labelSpacePermissionSettings => Intl.message("Permissions",
      name: "labelSpacePermissionSettings",
      desc: "Label for space permission settings");

  String get labelSpaceDeveloperSettings => Intl.message("Developer",
      name: "labelSpaceDeveloperSettings",
      desc: "Label for space developer settings");

  String get labelSettingsCategorySpace => Intl.message("Space Settings",
      name: "labelSettingsCategorySpace",
      desc: "Label for the overall space settings category");

  @override
  String get title => labelSettingsCategorySpace;

  @override
  List<SettingsTab> get tabs => getTabs();

  List<SettingsTab> getTabs() {
    SpaceEmoticonComponent? emoticons =
        space.getComponent<SpaceEmoticonComponent>();
    return List.from([
      SettingsTab(
          label: labelSpaceSettingsGeneral,
          icon: Icons.settings,
          pageBuilder: (context) {
            return SpaceGeneralSettingsPage(
              space: space,
            );
          }),
      SettingsTab(
          label: labelSpaceAppearanceSettings,
          icon: Icons.style,
          pageBuilder: (context) {
            return SpaceAppearanceSettingsPage(
              space: space,
            );
          }),
      if (emoticons != null &&
          (space.permissions.canEditRoomEmoticons ||
              emoticons.ownedPacks.isNotEmpty))
        SettingsTab(
            label: labelSpaceEmoticonSettings,
            icon: Icons.emoji_emotions,
            pageBuilder: (context) {
              return SpaceEmojiPackSettings(space);
            }),
      if (space is MatrixSpace)
        SettingsTab(
            label: labelSpacePermissionSettings,
            icon: Icons.admin_panel_settings,
            makeScrollable: false,
            pageBuilder: (context) {
              return MatrixRoomPermissionsPage(
                  (space as MatrixSpace).matrixRoom);
            }),
      if (preferences.developerMode.value)
        SettingsTab(
            label: labelSpaceDeveloperSettings,
            icon: Icons.code,
            makeScrollable: true,
            pageBuilder: (context) {
              return SpaceDeveloperSettingsView(space);
            }),
      if (space case MatrixSpace s)
        SettingsTab(
          label: "Members",
          icon: Icons.people,
          makeScrollable: false,
          pageBuilder: (context) {
            return RoomMemberList(MatrixRoom(space.client as MatrixClient,
                s.matrixRoom, s.matrixRoom.client));
          },
        )
    ]);
  }
}
