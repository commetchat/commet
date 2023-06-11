import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class WindowSettingsPage extends StatefulWidget {
  const WindowSettingsPage({super.key});

  @override
  State<WindowSettingsPage> createState() => _WindowSettingsPageState();
}

class _WindowSettingsPageState extends State<WindowSettingsPage> {
  bool minimizeOnClose = false;

  @override
  void initState() {
    minimizeOnClose = preferences.minimizeOnClose;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: "Window behaviour",
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                tiamat.Text.labelEmphasised("Minimize on close"),
                tiamat.Text.labelLow(
                    "When closing the window, the app will be minimized instead of exited")
              ],
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
