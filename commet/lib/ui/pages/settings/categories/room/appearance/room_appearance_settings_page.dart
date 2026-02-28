import 'dart:async';
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
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.room.onUpdate.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoomAppearanceSettingsView(
      client: widget.room.client,
      avatar: widget.room.avatar,
      displayName: widget.room.displayName,
      identifier: widget.room.identifier,
      color: widget.room.defaultColor,
      canEditName: widget.room.permissions.canEditName,
      canEditAvatar: widget.room.permissions.canEditAvatar,
      canEditTopic: widget.room.permissions.canEditTopic,
      topic: widget.room.topic,
      setTopic: widget.room.setTopic,
      onImagePicked: setRoomAvatar,
      onNameChanged: setRoomName,
    );
  }

  void setRoomAvatar(Uint8List bytes, String? mimeType) {
    widget.room.setRoomAvatar(bytes, mimeType);
  }

  void setRoomName(String name) {
    widget.room.setDisplayName(name);
  }
}
