import 'package:commet/client/client_manager.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/account/account_emoji/account_emoji_tab.dart';
import 'package:commet/ui/pages/settings/categories/account/account_state/account_state_tab.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_tab.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'account_management/account_management_tab.dart';
import 'security/security_tab.dart';

class SettingsCategoryAccount implements SettingsCategory {
  String get labelSettingsTabManageAccounts => Intl.message("Manage Accounts",
      name: "labelSettingsTabManageAccounts",
      desc: "Label for the Manage Accounts settings");

  String get labelSettingsTabProfile => Intl.message("Profile",
      name: "labelSettingsTabProfile",
      desc: "Label for the Profile settings page");

  String get labelSettingsTabSecurity => Intl.message("Security",
      name: "labelSettingsTabSecurity",
      desc: "Label for the Security settings page");

  String get labelSettingsTabEmoticons => Intl.message("Emoticons",
      name: "labelSettingsTabEmoticons",
      desc: "Label for the Emoticons settings page");

  String get labelSettingsTabDeveloper => Intl.message("Developer",
      name: "labelSettingsTabDeveloper",
      desc: "Label for the Developer settings page");

  String get labelSettingsCategoryAccount => Intl.message("Account",
      name: "labelSettingsCategoryAccount",
      desc: "Label for the settings category Account");

  @override
  String get title => labelSettingsCategoryAccount;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: labelSettingsTabManageAccounts,
            icon: Icons.person,
            pageBuilder: (context) {
              return AccountManagementSettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
            label: labelSettingsTabProfile,
            icon: Icons.account_circle,
            pageBuilder: (context) {
              return ProfileEditTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
            label: labelSettingsTabSecurity,
            icon: Icons.security,
            pageBuilder: (context) {
              return SecuritySettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
          label: labelSettingsTabEmoticons,
          icon: Icons.emoji_emotions,
          pageBuilder: (context) {
            return AccountEmojiTab(
                clientManager: Provider.of<ClientManager>(context));
          },
        ),
        if (preferences.developerMode.value)
          SettingsTab(
            label: labelSettingsTabDeveloper,
            icon: Icons.code,
            pageBuilder: (context) {
              return AccountStateTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            },
          )
      ]);
}
