import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  bool developerOptions = false;
  String get labelSettingsDeveloperMode => Intl.message("Developer mode",
      desc: "Header for the settings to enable developer mode",
      name: "labelSettingsDeveloperMode");

  String get labelSettingsDeveloperModeExplanation =>
      Intl.message("Shows extra information, useful for developers",
          desc: "Explains what developer mode does",
          name: "labelSettingsDeveloperModeExplanation");

  @override
  void initState() {
    developerOptions = preferences.developerMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: labelSettingsDeveloperMode,
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelEmphasised(labelSettingsDeveloperMode),
                tiamat.Text.labelLow(labelSettingsDeveloperModeExplanation)
              ],
            ),
            tiamat.Switch(
              state: developerOptions,
              onChanged: (value) async {
                setState(() {
                  developerOptions = value;
                });
                await preferences.setDeveloperMode(value);
                setState(() {
                  developerOptions = preferences.developerMode;
                });
              },
            )
          ],
        )
      ]),
    );
  }
}
