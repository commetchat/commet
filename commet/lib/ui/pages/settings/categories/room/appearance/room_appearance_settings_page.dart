import 'dart:typed_data';

import 'package:commet/client/room.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_view.dart';
import 'package:flutter/widgets.dart';

class RoomAppearanceSettingsPage extends StatefulWidget {
  const RoomAppearanceSettingsPage({super.key, required this.room});
  final Room room;
  @override
  State<RoomAppearanceSettingsPage> createState() =>
      _RoomAppearanceSettingsPageState();
}

class _RoomAppearanceSettingsPageState
    extends State<RoomAppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return RoomAppearanceSettingsView(
      avatar: widget.room.avatar,
      displayName: widget.room.displayName,
      identifier: widget.room.identifier,
      canEditName: widget.room.permissions.canEditName,
      canEditAvatar: widget.room.permissions.canEditAvatar,
      onImagePicked: setRoomAvatar,
      onNameChanged: setRoomName,
    );
  }

  setRoomAvatar(Uint8List bytes, String? mimeType) {}

  setRoomName(String name) {
    widget.room.setDisplayName(name);
  }
}
