import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/context_menu.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomTextButton extends StatefulWidget {
  const RoomTextButton(
    this.room, {
    this.highlight = false,
    this.onTap,
    super.key,
  });
  final bool highlight;
  final Room room;
  final Function(Room room)? onTap;

  @override
  State<RoomTextButton> createState() => _RoomTextButtonState();
}

class _RoomTextButtonState extends State<RoomTextButton> {
  late List<StreamSubscription> subs;
  VoipRoomComponent? voipRoom;
  CalendarRoom? calendarRoom;
  List<String>? voipRoomParticipants;
  List<MatrixCalendarEventState>? calendarEvents;

  @override
  void initState() {
    voipRoom = widget.room.getComponent<VoipRoomComponent>();
    calendarRoom = widget.room.getComponent<CalendarRoom>();

    subs = [
      widget.room.onUpdate.listen(onRoomUpdate),
      if (voipRoom != null)
        voipRoom!.onParticipantsChanged.listen(onVoipParticipantsChanged),
      if (calendarRoom != null)
        calendarRoom!.onEventsChanged.listen(onCalendarEventsChanged),
    ];

    if (voipRoom != null) {
      voipRoomParticipants = voipRoom?.getCurrentParticipants();
    }

    if (calendarRoom != null) {
      calendarEvents = calendarRoom!.getEventsOnDay(DateTime.now());
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

  void onCalendarEventsChanged(void event) {
    setState(() {
      calendarEvents = calendarRoom!.getEventsOnDay(DateTime.now());
    });
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

    if (calendarEvents?.isNotEmpty == true) {
      customBuilder = buildEvents;
    }

    Widget result = SizedBox(
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
                    padding: EdgeInsets.all(2.0), child: DotIndicator())
                : null,
      ),
    );

    if (voipRoom != null) {
      result = AdaptiveContextMenu(
        items: [
          if (preferences.developerMode)
            ContextMenuItem(
              text: "Clear Membership Status",
              icon: Icons.call_end,
              onPressed: () => voipRoom?.clearAllCallMembershipStatus(),
            ),
        ],
        child: result,
      );
    }

    return result;
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
        ),
      ],
    );
  }

  Widget buildEvents(Widget child, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height, child: child),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 0, 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  tiamat.Text.labelLow("Today: "),
                  for (var event in calendarEvents!) buildEvent(event),
                ],
              ),
            ),
          ),
        ),
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
      ),
    );
  }

  Widget buildEvent(MatrixCalendarEventState event) {
    var color = calendarRoom!.calendar.config.getColorFromUser(event.senderId!);

    return TinyPill(
      event.data.title,
      background: calendarRoom!.calendar.config.processEventColor(
        color,
        context,
      ),
      foreground: calendarRoom!.calendar.config.processEventTextColor(
        color,
        context,
      ),
    );
  }

  void onVoipParticipantsChanged(void event) {
    setState(() {
      voipRoomParticipants = voipRoom?.getCurrentParticipants();
    });
  }
}
