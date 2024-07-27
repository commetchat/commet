import 'dart:async';

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomTextButton extends StatefulWidget {
  const RoomTextButton(this.room,
      {this.highlight = false, this.onTap, super.key});
  final bool highlight;
  final Room room;
  final Function(Room room)? onTap;

  @override
  State<RoomTextButton> createState() => _RoomTextButtonState();
}

class _RoomTextButtonState extends State<RoomTextButton> {
  StreamSubscription? sub;

  @override
  void initState() {
    sub = widget.room.onUpdate.listen(onRoomUpdate);
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void onRoomUpdate(void event) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var isDm = widget.room.client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(widget.room) ??
        false;

    IconData icon = isDm ? Icons.alternate_email : Icons.tag;

    var color = Theme.of(context).colorScheme.secondary;

    if (widget.room.notificationCount > 0 ||
        widget.room.highlightedNotificationCount > 0 ||
        widget.highlight) color = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
        height: 30,
        child: tiamat.TextButton(
          highlighted: widget.highlight,
          widget.room.displayName,
          icon: icon,
          iconColor: color,
          textColor: color,
          softwrap: false,
          onTap: () => widget.onTap?.call(widget.room),
          footer: widget.room.displayHighlightedNotificationCount > 0
              ? NotificationBadge(
                  widget.room.displayHighlightedNotificationCount)
              : widget.room.displayNotificationCount > 0
                  ? const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: DotIndicator(),
                    )
                  : null,
        ));
  }
}
