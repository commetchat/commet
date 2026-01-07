import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/room_event_search/room_event_search_widget.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/room_pinned_messages/room_pinned_messages_widget.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu_mobile.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum SidePanelState { defaultView, thread, search, pinnedMessages, calendar }

class RoomSidePanel extends StatefulWidget {
  const RoomSidePanel({required this.state, this.builder, super.key});

  final MainPageState state;

  final Widget Function(SidePanelState state, Widget child)? builder;

  @override
  State<RoomSidePanel> createState() => _RoomSidePanelState();
}

class _RoomSidePanelState extends State<RoomSidePanel> {
  String? _currentThreadId;
  String? get currentThreadId => _currentThreadId;

  SidePanelState state = SidePanelState.defaultView;

  late List<StreamSubscription> subs;

  @override
  void initState() {
    subs = [
      EventBus.openThread.stream.listen(onOpenThreadSignal),
      EventBus.closeThread.stream.listen(onCloseThreadSignal),
      EventBus.startSearch.stream.listen(onStartSearch),
      EventBus.openPinnedMessages.stream.listen(onShowPinnedMessages),
      EventBus.openCalendar.stream.listen(onShowCalendar),
    ];
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = buildPanelContent(context);

    result = Material(
      color: Colors.transparent,
      child: result,
    );

    if (widget.builder != null) {
      result = widget.builder!.call(state, result);
    }

    // if (state == _SidePanelState.thread) {
    //   result = Flexible(child: result);
    // }

    return result;
  }

  Widget buildPanelContent(BuildContext context) {
    switch (state) {
      case SidePanelState.defaultView:
        return buildDefaultView();
      case SidePanelState.thread:
        return buildThread();
      case SidePanelState.search:
        return buildSearch();
      case SidePanelState.pinnedMessages:
        return buildPinnedMessages();
      case SidePanelState.calendar:
        return buildCalendar();
    }
  }

  void onOpenThreadSignal((String, String, String) event) {
    var clientId = event.$1;
    var roomId = event.$2;
    var threadId = event.$3;

    EventBus.openRoom.add((roomId, clientId));

    setState(() {
      _currentThreadId = threadId;
      state = SidePanelState.thread;
    });
  }

  void onCloseThreadSignal(void event) {
    setState(() {
      _currentThreadId = null;
      state = SidePanelState.defaultView;
    });
  }

  Widget buildDefaultView() {
    return Column(
      children: [
        if (Layout.mobile)
          RoomQuickAccessMenuViewMobile(
            room: widget.state.currentRoom!,
            key: ValueKey(
                "quick_access_menu_${widget.state.currentRoom!.localId}"),
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: RoomMembersListWidget(widget.state.currentRoom!),
          ),
        ),
      ],
    );
  }

  Widget buildThread() {
    return Tile(
      caulkPadLeft: true,
      caulkClipTopLeft: true,
      caulkClipBottomLeft: true,
      caulkPadBottom: true,
      child: Column(
        children: [
          Flexible(
            child: Stack(
              children: [
                Chat(
                  widget.state.currentRoom!,
                  threadId: currentThreadId,
                  key: ValueKey(
                      "room-timeline-key-${widget.state.currentRoom!.localId}_thread_$currentThreadId"),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: tiamat.CircleButton(
                      icon: Icons.close,
                      radius: 24,
                      onPressed: () => EventBus.closeThread.add(null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearch() {
    return SizedBox(
        width: Layout.desktop ? 300 : null,
        child: RoomEventSearchWidget(
          room: widget.state.currentRoom!,
          onEventClicked: (eventId) {
            EventBus.jumpToEvent.add(eventId);
            EventBus.focusTimeline.add(null);
          },
          close: () => setState(() {
            state = SidePanelState.defaultView;
          }),
        ));
  }

  void onStartSearch(void event) {
    setState(() {
      if (state == SidePanelState.search) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.search;
      }
    });
  }

  void onShowPinnedMessages(void event) {
    setState(() {
      if (state == SidePanelState.pinnedMessages) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.pinnedMessages;
      }
    });
  }

  void onShowCalendar(void event) {
    setState(() {
      if (state == SidePanelState.calendar) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.calendar;
      }
    });
  }

  Widget buildPinnedMessages() {
    return SizedBox(
        width: Layout.desktop ? 300 : null,
        child: Column(
          children: [
            if (Layout.mobile)
              RoomQuickAccessMenuViewMobile(
                room: widget.state.currentRoom!,
                key: ValueKey(
                    "quick_access_menu_${widget.state.currentRoom!.localId}"),
              ),
            Expanded(
              child: RoomPinnedMessagesWidget(
                room: widget.state.currentRoom!,
                onEventClicked: (eventId) {
                  EventBus.jumpToEvent.add(eventId);
                  EventBus.focusTimeline.add(null);
                },
              ),
            ),
          ],
        ));
  }

  Widget buildCalendar() {
    var calendar = widget.state.currentRoom?.getComponent<CalendarRoom>();
    if (calendar?.hasCalendar != true) {
      return Placeholder();
    }

    var query = MediaQuery.of(context);

    return tiamat.Tile.low(
      child: Column(
        children: [
          if (Layout.mobile)
            RoomQuickAccessMenuViewMobile(
              room: widget.state.currentRoom!,
              key: ValueKey(
                  "quick_access_menu_${widget.state.currentRoom!.localId}"),
            ),
          if (Layout.mobile)
            Divider(
              height: 2,
            ),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            var newQuery = query.copyWith(
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );

            return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: MediaQuery(
                    data: newQuery,
                    child: CalendarWidgetView(
                        calendar: calendar!.calendar!,
                        watermark: false,
                        useMobileLayout: Layout.mobile,
                        autoDisposeCalendar: false)));
          })),
        ],
      ),
    );
  }
}
