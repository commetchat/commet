import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/room/settings_category_room.dart';
import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoomSettingsPage extends StatefulWidget {
  const RoomSettingsPage({super.key, required this.room});
  final Room room;

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  String get promptLeaveRoom => Intl.message("Leave Room",
      desc: "Text on a button to leave a room", name: "promptLeaveRoom");

  String promptLeaveRoomConfirmation(String roomName) =>
      Intl.message("Are you sure you want to leave $roomName?",
          desc: "Text for the popup dialog confirming the intent to leave",
          args: [roomName],
          name: "promptLeaveRoomConfirmation");

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      settings: [
        SettingsCategoryRoom(
          widget.room,
        ),
      ],
      buttons: [
        SettingsButton(
            label: promptLeaveRoom,
            icon: Icons.subdirectory_arrow_left_rounded,
            color: Theme.of(context).colorScheme.error,
            onPress: () => leaveRoom(context)),
      ],
    );
  }

  Future<void> leaveRoom(BuildContext context) async {
    if (await AdaptiveDialog.confirmation(context,
            title: promptLeaveRoom,
            prompt: promptLeaveRoomConfirmation(widget.room.displayName),
            dangerous: true) ==
        true) {
      if (mounted) Navigator.pop(context);
      widget.room.client.leaveRoom(widget.room);
    }
  }
}
