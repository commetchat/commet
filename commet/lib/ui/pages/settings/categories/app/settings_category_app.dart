import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/advanced_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/appearance_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/window_settings.dart';
import 'package:commet/ui/pages/settings/categories/developer/developer_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart' as m;
import 'package:intl/intl.dart';

class SettingsCategoryApp implements SettingsCategory {
  String get labelSettingsAppGeneral => Intl.message("General",
      name: "labelSettingsAppGeneral",
      desc: "Label for the App General settings page");

  String get labelSettingsAppAppearance => Intl.message("Appearance",
      name: "labelSettingsAppAppearance",
      desc: "Label for the App Appearance settings page");

  String get labelSettingsWindowBehaviour => Intl.message("Window Behaviour",
      name: "labelSettingsWindowBehaviour",
      desc: "Label for the Window Behaviour settings page");

  String get labelSettingsAppAdvanced => Intl.message("Advanced",
      name: "labelSettingsAppAdvanced",
      desc: "Label for the App Advanced settings page");

  String get labelSettingsAppNotifications => Intl.message("Notifications",
      name: "labelSettingsAppNotifications",
      desc: "Label for the App notifications settings page");

  String get labelSettingsAppDeveloperUtils => Intl.message("Developer Utils",
      name: "labelSettingsAppDeveloperUtils",
      desc:
          "Label for the developer utils settings page, usually hidden unless developer mode is turned on");

  String get labelSettingsCategoryApp => Intl.message("App Settings",
      name: "labelSettingsCategoryApp",
      desc: "Label for the settings category of the overall App settings/");

  @override
  String get title => labelSettingsCategoryApp;

  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: labelSettingsAppGeneral,
            icon: m.Icons.settings,
            pageBuilder: (context) {
              return const GeneralSettingsPage();
            }),
        SettingsTab(
            label: labelSettingsAppAppearance,
            icon: m.Icons.style,
            pageBuilder: (context) {
              return const AppearanceSettingsPage();
            }),
        if (BuildConfig.DESKTOP)
          SettingsTab(
              label: labelSettingsWindowBehaviour,
              icon: m.Icons.window,
              pageBuilder: (context) {
                return const WindowSettingsPage();
              }),
        // We really only need to configure on unified push
        if (BuildConfig.ANDROID && !BuildConfig.ENABLE_GOOGLE_SERVICES)
          SettingsTab(
              label: labelSettingsAppNotifications,
              icon: m.Icons.notifications,
              pageBuilder: (context) {
                return const NotificationSettingsPage();
              }),
        SettingsTab(
            label: labelSettingsAppAdvanced,
            icon: m.Icons.code,
            pageBuilder: (context) {
              return const AdvancedSettingsPage();
            }),
        if (preferences.developerMode)
          SettingsTab(
            label: labelSettingsAppDeveloperUtils,
            icon: m.Icons.bug_report,
            pageBuilder: (context) {
              return const DeveloperSettingsPage();
            },
          ),
      ]);
}
