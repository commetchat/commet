import 'package:commet/utils/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class OutsourceShortcutSettingsPage extends StatelessWidget {
  const OutsourceShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      mode: TileType.surfaceContainerLow,
      header: "Configure Shortcuts",
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tiamat.Text(
              "In your current environment, keyboard shortcuts must be configured in your system settings."),
          tiamat.Button.secondary(
            text: "More Info",
            onTap: () => LinkUtils.open(
                Uri.parse("https://commet.chat/info/keyboard-shortcuts")),
          )
        ],
      ),
    );
  }
}
