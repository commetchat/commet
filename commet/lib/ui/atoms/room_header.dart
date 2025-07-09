import 'dart:async'; // For StreamSubscription

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/main.dart'; // For preferences
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';

class RoomHeader extends StatefulWidget {
  const RoomHeader(this.room, {super.key, this.onTap, this.menu});
  final Room room;
  final Widget? menu;
  final Function()? onTap;

  @override
  State<RoomHeader> createState() => _RoomHeaderState();
}

class _RoomHeaderState extends State<RoomHeader> {
  StreamSubscription? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _settingsSubscription = preferences.onSettingChanged.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showRoomIcons = preferences.showRoomAvatars;
    bool useGenericIcons = preferences.usePlaceholderRoomAvatars;

    bool shouldShowDefaultIcon = (!showRoomIcons && !useGenericIcons) ||
        (showRoomIcons && !useGenericIcons && widget.room.avatar == null);
    IconData defaultIcon = widget.room.icon;

    Widget iconWidget;
    if (shouldShowDefaultIcon) {
      iconWidget = m.Icon(
        defaultIcon,
        size: 30,
      );
    } else {
      iconWidget = tiamat.Avatar(
        radius: 15,
        image: showRoomIcons && widget.room.avatar != null
            ? widget.room.avatar
            : null,
        placeholderText:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.displayName
                : "",
        placeholderColor:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.defaultColor
                : m.Colors.grey,
      );
    }

    return m.Material(
      color: m.Colors.transparent,
      child: m.InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: iconWidget,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    child: m.Text(
                      widget.room.displayName,
                      style: m.Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (widget.menu != null) widget.menu!
            ],
          ),
        ),
      ),
    );
  }
}
