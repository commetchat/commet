import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/tiamat.dart';

import 'package:tiamat/config/config.dart';

class SettingsMenu {
  late List<SettingsTab> settings;

  SettingsMenu() {
    settings = List.from([
      SettingsTab(
          label: T.current.settingsTabAppearance,
          pageBuilder: (context) {
            return themeSettings(context);
          }),
    ]);
  }

  Widget themeSettings(BuildContext context) {
    return Column(children: [
      TextButton(T.of(context).themeLight, onTap: () {
        ThemeChanger.setTheme(context, ThemeLight.theme);
      }),
      TextButton(T.of(context).themeDark, onTap: () {
        ThemeChanger.setTheme(context, ThemeDark.theme);
      }),
      TextButton(T.of(context).themeGlass, onTap: () {
        ThemeChanger.setTheme(context, ThemeGlass.theme);
      }),
      Seperator(),
      TextButton(
        "Scale 1",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.0;
          };
        },
      ),
      TextButton(
        "Scale 1.25",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.25;
          };
        },
      ),
      TextButton(
        "Scale 1.5",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.5;
          };
        },
      ),
      TextButton(
        "Scale 1.75",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.75;
          };
        },
      )
    ]);
  }
}
