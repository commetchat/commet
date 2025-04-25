import 'package:commet/config/experiments.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class ExperimentsSettingsPage extends StatefulWidget {
  const ExperimentsSettingsPage({super.key});

  @override
  State<ExperimentsSettingsPage> createState() =>
      _ExperimentsSettingsPageState();
}

class _ExperimentsSettingsPageState extends State<ExperimentsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.label(
              "These features are still under development, and may contain bugs or security issues. Enable at your own risk"),
        ),
        Panel(
          header: "Experiments",
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tiamat.Text.labelEmphasised("1:1 Voice and Video Calls"),
                      tiamat.Text.labelLow(
                          "Enables peer to peer voice and video calls, using WebRTC")
                    ],
                  ),
                ),
                tiamat.Switch(
                  state: Experiments.voip,
                  onChanged: (value) async {
                    await Experiments.setVoip(value);
                    setState(() {});
                  },
                )
              ],
            )
          ]),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.error(
              "You must restart the app for changes to take effect"),
        ),
      ],
    );
  }
}
