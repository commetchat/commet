import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/space/settings_category_space.dart';
import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpaceSettingsPage extends StatefulWidget {
  const SpaceSettingsPage({super.key, required this.space});
  final Space space;

  @override
  State<SpaceSettingsPage> createState() => _SpaceSettingsPageState();
}

class _SpaceSettingsPageState extends State<SpaceSettingsPage> {
  String get promptLeaveSpace => Intl.message("Leave Space",
      desc: "Text on a button to leave a space", name: "promptLeaveSpace");

  String promptLeaveSpaceConfirmation(String spaceName) => Intl.message(
      "Are you sure you want to leave $spaceName?",
      desc: "Text for the popup dialog confirming the intent to leave a space",
      args: [spaceName],
      name: "promptLeaveSpaceConfirmation");

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      settings: [
        SettingsCategorySpace(
          widget.space,
        ),
      ],
      buttons: [
        SettingsButton(
            label: promptLeaveSpace,
            icon: Icons.subdirectory_arrow_left_rounded,
            color: Theme.of(context).colorScheme.error,
            onPress: () => leaveSpace(context)),
      ],
    );
  }

  Future<void> leaveSpace(BuildContext context) async {
    if (await AdaptiveDialog.confirmation(context,
            title: promptLeaveSpace,
            prompt: promptLeaveSpaceConfirmation(widget.space.displayName),
            dangerous: true) ==
        true) {
      if (context.mounted) Navigator.pop(context);
      widget.space.client.leaveSpace(widget.space);
    }
  }
}
