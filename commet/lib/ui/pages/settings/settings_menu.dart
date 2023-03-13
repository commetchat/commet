import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
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
      const Seperator(),
      const UIScaleSelector(),
    ]);
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: tiamat.Text(value.toString())),
        Expanded(
            child: Slider(
          min: 0.25,
          max: 2,
          value: 1,
          divisions: 7,
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
            ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
              return newValue;
            };
          },
        )
      ],
    );
  }
}
