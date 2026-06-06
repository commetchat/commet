import 'dart:async';

import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/text_utils.dart';
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
  final Function(Room room, {bool bypassSpecialRoomType})? onTap;

  @override
  State<RoomTextButton> createState() => _RoomTextButtonState();

  static List<ContextMenuItem> createRoomContextMenuItems(
      BuildContext context, Room room) {
    var voipRoom = room.getComponent<VoipRoomComponent>();
    return [
      ContextMenuItem(
          text: "Mark as Read",
          icon: Icons.visibility,
          onPressed: () => room.markAsRead()),
      if (!room.isFavorite)
        ContextMenuItem(
            text: "Set as Favorite",
            icon: Icons.favorite,
            onPressed: () => room.setAsFavorite(true)),
      if (room.isFavorite)
        ContextMenuItem(
            text: "Unfavorite",
            icon: Icons.heart_broken_outlined,
            onPressed: () => room.setAsFavorite(false)),
      if (room.isSpecialRoomType)
        ContextMenuItem(
            text: "Open as Text Chat",
            icon: Icons.tag,
            onPressed: () => EventBus.doOpenRoom(room.identifier,
                clientId: room.client.identifier)),
      if (voipRoom != null && preferences.developerMode.value)
        ContextMenuItem(
          text: "Clear Membership Status",
          icon: Icons.call_end,
          onPressed: () => voipRoom.clearAllCallMembershipStatus(),
        ),
      ContextMenuItem(
          text: "Settings",
          icon: Icons.settings,
          onPressed: () {
            NavigationUtils.navigateTo(
                context,
                RoomSettingsPage(
                  room: room,
                ));
          }),
    ];
  }
}

class _RoomTextButtonState extends State<RoomTextButton> {
  late List<StreamSubscription> subs;
  CalendarRoom? calendarRoom;
  ActivitiesComponent? activities;
  List<RoomActivitySession>? activitySessions;
  List<MatrixCalendarEventState>? calendarEvents;

  @override
  void initState() {
    calendarRoom = widget.room.getComponent<CalendarRoom>();
    activities = widget.room.getComponent<ActivitiesComponent>();

    subs = [
      widget.room.onUpdate.listen(onRoomUpdate),
      if (calendarRoom != null)
        calendarRoom!.onEventsChanged.listen(onCalendarEventsChanged),
      if (activities != null)
        activities!.onSessionsChanged.listen(onSessionsChanged),
    ];

    if (activities != null) {
      activitySessions = activities?.getSessions();
    }

    if (calendarRoom?.calendar != null) {
      onCalendarEventsChanged(());
    }

    if (activitySessions?.isNotEmpty == true) {
      for (var activity in activitySessions!) {
        for (var participant in activity.participants) {
          widget.room.fetchMember(participant).then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
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
      calendarEvents = calendarRoom!
          .getEventsOnDay(DateTime.now())
          .where((i) => i.isUnavailability == false)
          .toList();
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

    bool showRoomIcons = preferences.showRoomAvatars.value;
    bool useGenericIcons = preferences.usePlaceholderRoomAvatars.value;

    bool shouldShowDefaultIcon = (!showRoomIcons && !useGenericIcons) ||
        (showRoomIcons && !useGenericIcons && widget.room.avatar == null);

    String displayName = widget.room.displayName;

    Color? avatarPlaceholderColor =
        (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                (!showRoomIcons && useGenericIcons)
            ? widget.room.defaultColor
            : null;

    String? avatarPlaceholderText =
        (showRoomIcons && useGenericIcons && widget.room.avatar == null) ||
                (!showRoomIcons && useGenericIcons)
            ? widget.room.displayName
            : null;

    bool startsWithEmoji =
        TextUtils.isEmoji(widget.room.displayName.characters.first);

    if (startsWithEmoji && widget.room.avatar == null) {
      shouldShowDefaultIcon = false;
      var emoji = displayName.characters.first;
      displayName = displayName.characters.skip(1).string.trim();
      avatarPlaceholderColor = Colors.transparent;
      avatarPlaceholderText = emoji;
    }
    var customBuilder = null;

    if (calendarEvents?.isNotEmpty == true) {
      customBuilder = buildEvents;
    }

    if (activitySessions?.isNotEmpty == true) {
      customBuilder = buildActivities;
    }

    Widget result = SizedBox(
      height: customBuilder == null ? height : null,
      child: tiamat.TextButton(
        displayName,
        customBuilder: customBuilder,
        highlighted: widget.highlight,
        icon: shouldShowDefaultIcon ? defaultIcon : null,
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
        footer: widget.room.displayHighlightedNotificationCount > 0
            ? NotificationBadge(widget.room.displayHighlightedNotificationCount)
            : widget.room.displayNotificationCount > 0
                ? const Padding(
                    padding: EdgeInsets.all(2.0), child: DotIndicator())
                : null,
      ),
    );

    result = AdaptiveContextMenu(
      items: RoomTextButton.createRoomContextMenuItems(context, widget.room),
      child: result,
    );

    return result;
  }

  Widget buildActivities(Widget child, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: height, child: child),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 4),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var activity in activitySessions!) buildActivity(activity),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActivity(RoomActivitySession activity) {
    return AdaptiveContextMenu(
      items: [
        tiamat.ContextMenuItem(text: "Clear Memberships", onPressed: () {
          activities!.clearMemberships(activity);
        },),
      ],
      child: Container(
        decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceTint.withAlpha(10),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.thirdparty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                child: tiamat.Text.labelLow(activity.name),
              ),
            for (var participant in activity.participants)
              buildCallMember(participant),
          ],
        ),
      ),
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

    final member = widget.room.getMemberOrFallback(identifier);

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
    var color =
        calendarRoom!.calendar!.config.getColorFromUser(event.senderId!);

    return TinyPill(
      event.data.title,
      background: calendarRoom!.calendar!.config.processEventColor(
        color,
        context,
      ),
      foreground: calendarRoom!.calendar!.config.processEventTextColor(
        color,
        context,
      ),
    );
  }

  void onSessionsChanged(void event) {
    setState(() {
      activitySessions = activities?.getSessions();
    });
  }
}
