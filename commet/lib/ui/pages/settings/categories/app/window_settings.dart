import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class WindowSettingsPage extends StatefulWidget {
  const WindowSettingsPage({super.key});

  @override
  State<WindowSettingsPage> createState() => _WindowSettingsPageState();
}

class _WindowSettingsPageState extends State<WindowSettingsPage> {
  bool minimizeOnClose = false;

  String get labelSettingsWindowBehaviourTitle =>
      Intl.message("Window behaviour",
          desc: "Header for the window behaviour section of settings",
          name: "labelSettingsWindowBehaviourTitle");

  String get labelSettingsMinimizeOnCloseToggle =>
      Intl.message("Minimize on close",
          desc: "Label for the toggle to turn on and off minimize on close",
          name: "labelSettingsMinimizeOnCloseToggle");

  String get labelSettingsMinimizeOnCloseExplanation => Intl.message(
      "When closing the window, the app will be minimized instead of exited",
      desc: "Explains what the 'minimize on close' setting does",
      name: "labelSettingsMinimizeOnCloseExplanation");

  @override
  void initState() {
    minimizeOnClose = preferences.minimizeOnClose;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: labelSettingsWindowBehaviourTitle,
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(
                      labelSettingsMinimizeOnCloseToggle),
                  tiamat.Text.labelLow(labelSettingsMinimizeOnCloseExplanation)
                ],
              ),
            ),
            tiamat.Switch(
              state: preferences.minimizeOnClose,
              onChanged: (value) async {
                setState(() {
                  minimizeOnClose = value;
                });
                await preferences.setMinimizeOnClose(value);
                setState(() {
                  minimizeOnClose = preferences.minimizeOnClose;
                });
              },
            )
          ],
        )
      ]),
    );
  }
}
