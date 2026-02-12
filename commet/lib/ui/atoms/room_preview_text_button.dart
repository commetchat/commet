import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPreviewTextButton extends StatefulWidget {
  const RoomPreviewTextButton(
    this.room, {
    this.onTap,
    super.key,
  });
  final RoomPreview room;
  final Function(RoomPreview roomPreview)? onTap;

  @override
  State<RoomPreviewTextButton> createState() => _RoomPreviewTextButtonState();
}

class _RoomPreviewTextButtonState extends State<RoomPreviewTextButton> {
  @override
  void initState() {
    super.initState();
  }

  static const double height = 37;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.secondary;

    bool showRoomIcons = preferences.showRoomAvatars;
    bool useGenericIcons = preferences.usePlaceholderRoomAvatars;

    String displayName = widget.room.displayName;

    Color? avatarPlaceholderColor =
        (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                (!showRoomIcons && useGenericIcons)
            ? widget.room.color
            : null;

    String? avatarPlaceholderText =
        (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                (!showRoomIcons && useGenericIcons)
            ? widget.room.displayName
            : null;

    bool startsWithEmoji =
        TextUtils.isEmoji(widget.room.displayName.characters.first);

    if (startsWithEmoji && widget.room.avatar == null) {
      var emoji = displayName.characters.first;
      displayName = displayName.characters.skip(1).string.trim();
      avatarPlaceholderColor = Colors.transparent;
      avatarPlaceholderText = emoji;
    }
    var customBuilder = null;

    IconData? icon = null;
    if (widget.room.type == RoomType.defaultRoom) {
      icon = Icons.tag;
    }
    if (widget.room.type == RoomType.calendar) {
      icon = Icons.calendar_month;
    }
    if (widget.room.type == RoomType.photoAlbum) {
      icon = Icons.photo;
    }
    if (widget.room.type == RoomType.space) {
      icon = Icons.star; // IDK what to put here
    }
    if (widget.room.type == RoomType.voipRoom) {
      icon = Icons.volume_up;
    }

    Widget result = SizedBox(
        height: customBuilder == null ? height : null,
        child: tiamat.TextButton(
          displayName,
          customBuilder: customBuilder,
          icon: icon,
          avatar: showRoomIcons && widget.room.avatar != null
              ? widget.room.avatar
              : null,
          avatarRadius: 12,
          avatarPlaceholderColor: avatarPlaceholderColor,
          avatarPlaceholderText: avatarPlaceholderText,
          iconColor: color,
          textColor: color,
          softwrap: false,
          onTap: () => widget.onTap?.call(widget.room),
          footer: Text(CommonStrings.promptJoin),
        ));

    return result;
  }
}
