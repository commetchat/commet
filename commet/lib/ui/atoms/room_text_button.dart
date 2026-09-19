import 'dart:async';

import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/soundboard/entrance_sound.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/dj/dj_booths.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/live_media_indicator.dart';
import 'package:commet/ui/atoms/speaking_indicator.dart';
import 'package:commet/ui/atoms/voice_state_indicator.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/organisms/dj/dj_booth_panel.dart';
import 'package:commet/ui/organisms/dj/dj_member_ui.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:flutter/foundation.dart';
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
                clientId: room.client.identifier, bypassSpecialRoomType: true)),
      if (voipRoom != null &&
          voipRoom.canJoinCall &&
          voipRoom.currentSession == null &&
          preferences.soundboardEntranceSoundId.value != null)
        ContextMenuItem(
            text: "Join Without Entrance Sound",
            icon: Icons.volume_off,
            onPressed: () {
              EntranceSoundGate.instance.requestSilentJoin(room.identifier);
              EventBus.doOpenRoom(room.identifier,
                  clientId: room.client.identifier);
            }),
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

  /// Our call in this room, while we are in it. Only then do we hear the
  /// members, so only then can the list show who is speaking.
  VoipSession? voiceSession;
  StreamSubscription? voiceLevelSub;
  Set<String> speakingMembers = const {};

  @override
  void initState() {
    calendarRoom = widget.room.getComponent<CalendarRoom>();
    activities = widget.room.getComponent<ActivitiesComponent>();
    final isVoiceRoom = widget.room.getComponent<VoipRoomComponent>() != null;

    subs = [
      widget.room.onUpdate.listen(onRoomUpdate),
      if (calendarRoom != null)
        calendarRoom!.onEventsChanged.listen(onCalendarEventsChanged),
      if (activities != null)
        activities!.onSessionsChanged.listen(onSessionsChanged),
      if (isVoiceRoom && clientManager != null)
        clientManager!.callManager.currentSessions.onListUpdated
            .listen((_) => attachVoiceSession()),
      if (isVoiceRoom)
        DjBooths.onChanged.listen((_) {
          if (mounted) setState(() {});
        }),
    ];

    if (isVoiceRoom) attachVoiceSession();

    if (activities != null) {
      activitySessions = activities?.getSessions();
      sortActivities();
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

  void onSessionsChanged(void event) {
    setState(() {
      activitySessions = activities?.getSessions();
      sortActivities();
    });
  }

  void sortActivities() {
    activitySessions?.sort(
        (a, b) => (a.thirdparty ? 1 : 0).compareTo(b.thirdparty ? 1 : 0));
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    voiceLevelSub?.cancel();
    super.dispose();
  }

  void attachVoiceSession() {
    final session =
        widget.room.getComponent<VoipRoomComponent>()?.currentSession;
    if (identical(session, voiceSession)) return;

    voiceLevelSub?.cancel();
    voiceSession = session;
    voiceLevelSub =
        session?.onUpdateVolumeVisualizers.listen((_) => updateSpeaking());
    updateSpeaking();
  }

  /// Everyone whose voice is coming through right now, ourselves included.
  /// Screen share audio is not someone talking.
  void updateSpeaking() {
    final session = voiceSession;
    final speaking = session == null
        ? const <String>{}
        : session.streams
            .where((stream) =>
                stream.type != VoipStreamType.screenshare &&
                stream.type != VoipStreamType.screenshareAudio &&
                stream.type != VoipStreamType.music &&
                stream.audiolevel > 0.5)
            .map((stream) => stream.streamUserId)
            .toSet();

    if (setEquals(speaking, speakingMembers)) return;
    if (!mounted) return;
    setState(() => speakingMembers = speaking);
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
    Iterable<RoomActivitySession> sessions = activitySessions!;

    if (activitySessions!.any((i) => i.thirdparty == false)) {
      sessions = activitySessions!.where((i) => i.thirdparty == false);
    }

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
              for (var activity in sessions)
                buildActivity(
                  activity,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActivity(RoomActivitySession activity) {
    return AdaptiveContextMenu(
      items: [
        tiamat.ContextMenuItem(
          text: "Clear Memberships",
          onPressed: () {
            activities!.clearMemberships(activity);
          },
        ),
      ],
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceTint.withAlpha(10),
            borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: activity.associatedWidget == null
                ? null
                : () => onWidgetTapped(activity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.thirdparty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
                    child: Row(
                      spacing: 8,
                      children: [
                        SizedBox(
                            height: 20,
                            width: 20,
                            child: activity.icon.build(context)),
                        tiamat.Text.labelLow(activity.name),
                      ],
                    ),
                  ),
                if (activity.thirdparty)
                  tiamat.Seperator(
                    padding: 2,
                  ),
                for (var participant in activity.participants)
                  buildCallMember(participant,
                      showActivityIcons: activity.thirdparty == false,
                      liveMedia: activity.liveMedia[participant] ?? const {},
                      voiceState: activity.voiceState[participant] ?? const {}),
              ],
            ),
          ),
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

  Widget buildCallMember(String identifier,
      {bool showActivityIcons = true,
      Set<LiveMedia> liveMedia = const {},
      Set<VoiceState> voiceState = const {}}) {
    var color = Theme.of(context).colorScheme.secondary;

    final member = widget.room.getMemberOrFallback(identifier);

    bool canShowActivityIcons = activitySessions != null && showActivityIcons;

    // Only in our own call: the booth is heard over its data channel.
    final dj = showActivityIcons ? DjBooths.of(voiceSession) : null;

    final row = SizedBox(
      height: height,
      child: tiamat.TextButton(
        member.displayName,
        textColor: color,
        avatar: member.avatar,
        avatarPlaceholderColor: member.defaultColor,
        avatarPlaceholderText: member.displayName,
        // Scaled down from the call tiles to stay inside this row.
        avatarBuilder: (avatar) => SpeakingIndicator(
          // Voice members only, not people in a third party activity.
          speaking: showActivityIcons && speakingMembers.contains(identifier),
          radius: 12,
          ringGap: 1.5,
          ringWidth: 2,
          waveTravel: 5,
          child: avatar,
        ),
        footer: canShowActivityIcons
            ? Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child: Row(
                  children: [
                    if (dj != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                        child: DjMemberBadges(dj: dj, userId: identifier),
                      ),
                    if (voiceState.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                        child: VoiceStateIndicator(voiceState),
                      ),
                    if (liveMedia.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: LiveMediaIndicator(liveMedia),
                      ),
                    for (var i in activitySessions!.where((i) =>
                        i.thirdparty == true &&
                        i.participants.contains(identifier)))
                      ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: i.associatedWidget == null
                                ? null
                                : () => onWidgetTapped(i),
                            child: SizedBox(
                                height: 30,
                                width: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: i.icon.build(context),
                                )),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );

    if (dj == null) return row;
    // Built when the menu opens, so it matches the booth at that moment.
    return ListenableBuilder(
      listenable: dj,
      builder: (context, child) => AdaptiveContextMenu(
        items: djMemberMenuItems(dj,
            userId: identifier,
            displayName: member.displayName,
            musicVolume: DjMusicVolume(session: voiceSession!)),
        child: child!,
      ),
      child: row,
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

  Future<void> onWidgetTapped(RoomActivitySession activity) async {
    bool isInActivity = WidgetComponent.currentSessions.any(
      (element) =>
          element.info.type == activity.application &&
          widget.room == element.room,
    );

    if (isInActivity == false) {
      var confirm = await AdaptiveDialog.confirmation(context,
          prompt: "Open **${activity.associatedWidget!.name}**?");
      if (confirm == true) {
        WidgetComponent.runWidget(
            widget.room, context, activity.associatedWidget!);
      }
    } else {
      Log.i("Already has a widget in for this session");
    }
  }
}
