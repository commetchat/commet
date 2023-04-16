import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/config/config.dart';
import 'package:scaled_app/scaled_app.dart';

import 'account_management_tab.dart';
import 'security_tab.dart';

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
            label: T.current.settingsTabAccountSecurity,
            icon: Icons.security,
            pageBuilder: (context) {
              return SecuritySettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
      ]);

  @override
  String get title => T.current.settingsCategoryAccount;
}
