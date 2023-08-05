import 'package:commet/client/client_manager.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/account/account_emoji/account_emoji_tab.dart';
import 'package:commet/ui/pages/settings/categories/account/account_state/account_state_tab.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_tab.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'account_management/account_management_tab.dart';
import 'security/security_tab.dart';

class SettingsCategoryAccount implements SettingsCategory {
  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: T.current.settingsTabManageAccounts,
            icon: Icons.person,
            pageBuilder: (context) {
              return AccountManagementSettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
            label: "Profile",
            icon: Icons.account_circle,
            pageBuilder: (context) {
              return ProfileEditTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
            label: T.current.settingsTabAccountSecurity,
            icon: Icons.security,
            pageBuilder: (context) {
              return SecuritySettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
        SettingsTab(
          label: "Emoji",
          icon: Icons.emoji_emotions,
          pageBuilder: (context) {
            return AccountEmojiTab(
                clientManager: Provider.of<ClientManager>(context));
          },
        ),
        if (preferences.developerMode)
          SettingsTab(
            label: "Developer",
            icon: Icons.code,
            pageBuilder: (context) {
              return AccountStateTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            },
          )
      ]);

  @override
  String get title => T.current.settingsCategoryAccount;
}
