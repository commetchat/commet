import 'package:commet/config/preferences.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;
import 'package:intl/intl.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late bool shouldFollowSystemTheme;

  String get labelSettingsAppTheme => Intl.message("Theme",
      name: "labelSettingsAppTheme",
      desc: "Label for theme section of app appearance");

  String get labelThemeDark => Intl.message("Dark Theme",
      name: "labelThemeDark", desc: "Label for the dark theme");

  String get labelThemeLight => Intl.message("Light Theme",
      name: "labelThemeLight", desc: "Label for the light theme");

  String get labelThemeAmoled => Intl.message("Amoled",
      name: "labelThemeAmoled", desc: "Label for the light theme");

  String get labelAppScale => Intl.message("App Scale",
      name: 'labelAppScale',
      desc:
          "Label for the setting which controls the UI scale of the overall app");

  @override
  void initState() {
    shouldFollowSystemTheme = preferences.shouldFollowSystemTheme;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        themeSettings(context),
        Panel(
          header: labelAppScale,
          mode: TileType.surfaceLow2,
          child: const UIScaleSelector(),
        )
      ],
    );
  }

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
            TextButton(labelThemeAmoled, onTap: () {
              preferences.setTheme(AppTheme.amoled);
              ThemeChanger.setTheme(context, ThemeAmoled.theme);
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: GeneralSettingsPageState.settingToggle(
                shouldFollowSystemTheme,
                title: "Follow System Theme",
                description: "Automatically follow System Theme",
                onChanged: (value) {
                  setState(() {
                    shouldFollowSystemTheme = value;
                    preferences.setShouldFollowSystemTheme(value);
                  });
                  if (value) {
                    ThemeChanger.updateSystemTheme(context);
                  } else {
                    var theme = {
                      AppTheme.dark: ThemeDark.theme,
                      AppTheme.light: ThemeLight.theme,
                      AppTheme.amoled: ThemeAmoled.theme,
                    }[preferences.theme];
                    ThemeChanger.setTheme(context, theme!);
                  }
                },
              ),
            ),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
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
