import 'dart:async';

import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
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
  late List<StreamSubscription> subs;
  VoipRoomComponent? voipRoom;
  List<String>? voipRoomParticipants;

  @override
  void initState() {
    voipRoom = widget.room.getComponent<VoipRoomComponent>();
    subs = [
      widget.room.onUpdate.listen(onRoomUpdate),
      if (voipRoom?.isVoipRoom == true)
        voipRoom!.onParticipantsChanged.listen(onVoipParticipantsChanged),
    ];

    if (voipRoom?.isVoipRoom == true) {
      voipRoomParticipants = voipRoom?.getCurrentParticipants();
    }

    if (voipRoomParticipants?.isNotEmpty == true) {
      for (var participant in voipRoomParticipants!) {
        widget.room.fetchMember(participant).then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void onRoomUpdate(void event) {
    setState(() {});
  }

  static const double height = 37;

  @override
  Widget build(BuildContext context) {
    IconData defaultIcon = widget.room.icon;

    var color = Theme.of(context).colorScheme.secondary;

    if (widget.room.notificationCount > 0 ||
        widget.room.highlightedNotificationCount > 0 ||
        widget.highlight) {
      color = Theme.of(context).colorScheme.onSurface;
    }

    bool showRoomIcons = preferences.showRoomAvatars;
    bool useGenericIcons = preferences.usePlaceholderRoomAvatars;

    bool shouldShowDefaultIcon = (!showRoomIcons && !useGenericIcons) ||
        (showRoomIcons && !useGenericIcons && widget.room.avatar == null);

    var customBuilder = null;

    if (voipRoomParticipants?.isNotEmpty == true) {
      customBuilder = buildCallParticipants;
    }

    return SizedBox(
      height: customBuilder == null ? height : null,
      child: tiamat.TextButton(
        customBuilder: customBuilder,
        highlighted: widget.highlight,
        widget.room.displayName,
        icon: shouldShowDefaultIcon ? defaultIcon : null,
        avatar: showRoomIcons && widget.room.avatar != null
            ? widget.room.avatar
            : null,
        avatarRadius: 12,
        avatarPlaceholderColor:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.defaultColor
                : null,
        avatarPlaceholderText:
            (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                    (!showRoomIcons && useGenericIcons)
                ? widget.room.displayName
                : null,
        iconColor: color,
        textColor: color,
        softwrap: false,
        onTap: () => widget.onTap?.call(widget.room),
        footer: widget.room.displayHighlightedNotificationCount > 0
            ? NotificationBadge(widget.room.displayHighlightedNotificationCount)
            : widget.room.displayNotificationCount > 0
                ? const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: DotIndicator(),
                  )
                : null,
      ),
    );
  }

  Widget buildCallParticipants(Widget child, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height, child: child),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 4),
          child: Column(
            children: [
              for (var participant in voipRoomParticipants!)
                buildCallMember(participant),
            ],
          ),
        )
      ],
    );
  }

  Widget buildCallMember(String identifier) {
    var color = Theme.of(context).colorScheme.secondary;

    final member = voipRoom?.room.getMemberOrFallback(identifier);
    if (member == null) {
      return Placeholder();
    }

    return SizedBox(
        height: height,
        child: tiamat.TextButton(
          member.displayName,
          textColor: color,
          avatar: member.avatar,
          avatarPlaceholderColor: member.defaultColor,
          avatarPlaceholderText: member.displayName,
        ));
  }

  void onVoipParticipantsChanged(void event) {
    setState(() {
      voipRoomParticipants = voipRoom?.getCurrentParticipants();
    });
  }
}
