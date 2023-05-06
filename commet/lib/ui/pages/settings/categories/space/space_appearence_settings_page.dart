import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/room/appearence/room_appearence_settings_view.dart';
import 'package:flutter/widgets.dart';

class SpaceAppearanceSettingsPage extends StatefulWidget {
  const SpaceAppearanceSettingsPage({super.key, required this.space});
  final Space space;
  @override
  State<SpaceAppearanceSettingsPage> createState() =>
      _SpaceAppearanceSettingsPageState();
}

class _SpaceAppearanceSettingsPageState
    extends State<SpaceAppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return RoomAppearanceSettingsView(
      avatar: widget.space.avatar,
      displayName: widget.space.displayName,
      identifier: widget.space.identifier,
      onImagePicked: onAvatarPicked,
      onNameChanged: setName,
      canEditName: widget.space.permissions.canEditName,
      canEditAvatar: widget.space.permissions.canEditAvatar,
    );
  }

  onAvatarPicked(Uint8List bytes, String? mimeType) {
    widget.space.changeAvatar(bytes, mimeType);
  }

  setName(String name) {
    widget.space.setDisplayName(name);
  }
}
