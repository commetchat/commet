import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  bool developerOptions = false;

  @override
  void initState() {
    developerOptions = preferences.developerMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: "Developer mode",
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelEmphasised("Developer mode"),
                tiamat.Text.labelLow(
                    "Shows extra information, useful for developers")
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
