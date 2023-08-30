import 'package:commet/config/build_config.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/advanced_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/window_settings.dart';
import 'package:commet/ui/pages/settings/categories/developer/developer_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/config/config.dart';

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

  String get labelSettingsAppDeveloperUtils => Intl.message("Developer Utils",
      name: "labelSettingsAppDeveloperUtils",
      desc:
          "Label for the developer utils settings page, usually hidden unless developer mode is turned on");

  String get labelSettingsAppTheme => Intl.message("Theme",
      name: "labelSettingsAppTheme",
      desc: "Label for theme section of app appearance");

  String get labelThemeDark => Intl.message("Dark Theme",
      name: "labelThemeDark", desc: "Label for the dark theme");

  String get labelThemeLight => Intl.message("Light Theme",
      name: "labelThemeLight", desc: "Label for the light theme");

  String get labelAppScale => Intl.message("App Scale",
      name: 'labelAppScale',
      desc:
          "Label for the setting which controls the UI scale of the overall app");

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
              return themeSettings(context);
            }),
        if (BuildConfig.DESKTOP)
          SettingsTab(
              label: labelSettingsWindowBehaviour,
              icon: m.Icons.window,
              pageBuilder: (context) {
                return const WindowSettingsPage();
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
          )
      ]);

  Widget themeSettings(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: labelSettingsAppTheme,
          mode: TileType.surfaceLow2,
          child: Column(children: [
            TextButton(labelThemeLight, onTap: () {
              preferences.setTheme(AppTheme.light);
              ThemeChanger.setTheme(context, ThemeLight.theme);
            }),
            TextButton(labelThemeDark, onTap: () {
              preferences.setTheme(AppTheme.dark);
              ThemeChanger.setTheme(context, ThemeDark.theme);
            }),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        if (BuildConfig.DESKTOP || preferences.developerMode)
          Panel(
            header: labelAppScale,
            mode: TileType.surfaceLow2,
            child: const UIScaleSelector(),
          )
      ],
    );
  }
}

class UIScaleSelector extends StatefulWidget {
  const UIScaleSelector({super.key});

  @override
  State<UIScaleSelector> createState() => _UIScaleSelectorState();
}

class _UIScaleSelectorState extends State<UIScaleSelector> {
  double value = 1;

  @override
  void initState() {
    value = preferences.appScale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          SizedBox(width: 30, child: tiamat.Text(value.toStringAsPrecision(2))),
          Expanded(
              child: Slider(
            min: 0.5,
            max: preferences.developerMode ? 3 : 2,
            value: value,
            divisions: preferences.developerMode ? 25 : 15,
            onChanged: (value) {
              setState(() {
                this.value = value;
              });
            },
          )),
          Button.secondary(
            text: CommonStrings.promptApply,
            onTap: () {
              double newValue = value;
              preferences.setAppScale(newValue);
              ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
                return newValue;
              };
            },
          )
        ],
      ),
    );
  }
}
