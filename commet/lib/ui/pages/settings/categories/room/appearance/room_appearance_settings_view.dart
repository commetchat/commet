import 'dart:typed_data';

import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_view.dart';
import 'package:flutter/material.dart';

class RoomAppearanceSettingsView extends StatefulWidget {
  const RoomAppearanceSettingsView(
      {required this.avatar,
      required this.displayName,
      required this.identifier,
      this.onImagePicked,
      this.onNameChanged,
      this.canEditName = false,
      this.canEditAvatar = false,
      super.key});
  final ImageProvider? avatar;
  final String displayName;
  final String identifier;
  final Function(Uint8List bytes, String? mimeType)? onImagePicked;
  final Function(String name)? onNameChanged;
  final bool canEditName;
  final bool canEditAvatar;
  @override
  State<RoomAppearanceSettingsView> createState() =>
      _RoomAppearanceSettingsViewState();
}

class _RoomAppearanceSettingsViewState
    extends State<RoomAppearanceSettingsView> {
  @override
  Widget build(BuildContext context) {
    return ProfileEditView(
      avatar: widget.avatar,
      displayName: widget.displayName,
      identifier: widget.identifier,
      pickAvatar: (bytes, type) => widget.onImagePicked?.call(bytes, type),
      setDisplayName: (name) => widget.onNameChanged?.call(name),
      canEditName: widget.canEditName,
      canEditAvatar: widget.canEditAvatar,
    );
  }
}
