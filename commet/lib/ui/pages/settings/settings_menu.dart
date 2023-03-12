import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/atoms/seperator.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:scaled_app/scaled_app.dart';

import '../../../config/style/theme_changer.dart';
import '../../../config/style/theme_dark.dart';
import '../../../config/style/theme_glass.dart';
import '../../../config/style/theme_light.dart';
import '../../atoms/simple_text_button.dart';

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
      SimpleTextButton(T.of(context).themeLight, onTap: () {
        ThemeChanger.setTheme(context, ThemeLight().theme);
      }),
      SimpleTextButton(T.of(context).themeDark, onTap: () {
        ThemeChanger.setTheme(context, ThemeDark.theme);
      }),
      SimpleTextButton(T.of(context).themeGlass, onTap: () {
        ThemeChanger.setTheme(context, ThemeGlass().theme);
      }),
      Seperator(),
      SimpleTextButton(
        "Scale 1",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.0;
          };
        },
      ),
      SimpleTextButton(
        "Scale 1.25",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.25;
          };
        },
      ),
      SimpleTextButton(
        "Scale 1.5",
        onTap: () {
          ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
            return 1.5;
          };
        },
      ),
      SimpleTextButton(
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
