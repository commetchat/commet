import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomTextButton extends StatelessWidget {
  const RoomTextButton(this.room,
      {this.highlight = false, this.onTap, super.key});
  final bool highlight;
  final Room room;
  final Function(Room room)? onTap;

  @override
  Widget build(BuildContext context) {
    IconData icon = room.isDirectMessage ? Icons.alternate_email : Icons.tag;

    var color = Theme.of(context).colorScheme.secondary;

    if (room.notificationCount > 0 ||
        room.highlightedNotificationCount > 0 ||
        highlight) color = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
        height: 30,
        child: tiamat.TextButton(
          highlighted: highlight,
          room.displayName,
          icon: icon,
          iconColor: color,
          textColor: color,
          onTap: () => onTap?.call(room),
          footer: room.displayHighlightedNotificationCount > 0
              ? NotificationBadge(room.displayHighlightedNotificationCount)
              : room.displayNotificationCount > 0
                  ? const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: DotIndicator(),
                    )
                  : null,
        ));
  }
}
