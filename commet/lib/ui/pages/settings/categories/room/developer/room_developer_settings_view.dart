import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:flutter/material.dart';
import 'package:commet/main.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomDeveloperSettingsView extends StatelessWidget {
  final Room room;
  const RoomDeveloperSettingsView(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children:
            [jsonDump(context), notificationTests(context)].map<Widget>((e) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: e),
      );
    }).toList());
  }

  Widget jsonDump(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Room State"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        SelectionArea(
          child: Codeblock(
            language: "json",
            text: room.developerInfo,
          ),
        )
      ],
    );
  }

  Widget notificationTests(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Shortcuts"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Register Shortcut",
            onTap: () => shortcutsManager.createShortcutForRoom(room),
          ),
          tiamat.Button(
            text: "Clear All Shortcuts",
            onTap: () => shortcutsManager.clearAllShortcuts(),
          ),
        ])
      ],
    );
  }
}
