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
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.label(
            "These features are still under development, and may contain bugs or security issues. Enable at your own risk",
          ),
        ),
        Panel(
          header: "Experiments",
          mode: TileType.surfaceContainerLow,
          child: Column(
            children: [],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.error(
            "You must restart the app for changes to take effect",
          ),
        ),
      ],
    );
  }
}
