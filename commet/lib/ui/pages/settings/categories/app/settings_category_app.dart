import 'package:commet/config/preferences.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/config/config.dart';
import 'package:scaled_app/scaled_app.dart';

class SettingsCategoryAppearence implements SettingsCategory {
  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: T.current.settingsTabAppearance,
            icon: m.Icons.style,
            pageBuilder: (context) {
              return themeSettings(context);
            }),
      ]);

  @override
  String get title => T.current.settingsCategoryApp;

  Widget themeSettings(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: "Theme",
          mode: TileType.surfaceLow2,
          child: Column(children: [
            TextButton(T.of(context).themeLight, onTap: () {
              preferences.setTheme(AppTheme.light);
              ThemeChanger.setTheme(context, ThemeLight.theme);
            }),
            TextButton(T.of(context).themeDark, onTap: () {
              preferences.setTheme(AppTheme.dark);
              ThemeChanger.setTheme(context, ThemeDark.theme);
            }),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        const Panel(
          header: "UI Scale",
          mode: TileType.surfaceLow2,
          child: UIScaleSelector(),
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
    value = preferences.getAppScale();
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
            max: 2,
            value: value,
            divisions: 15,
            onChanged: (value) {
              setState(() {
                this.value = value;
              });
            },
          )),
          Button.secondary(
            text: "Apply",
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
