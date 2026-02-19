import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/drag_drop_file_target.dart';

import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/organisms/background_task_view/background_task_view_container.dart';
import 'package:commet/ui/organisms/home_screen/home_screen.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu_desktop.dart';
import 'package:commet/ui/organisms/room_side_panel/room_side_panel.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_calls_list.dart';
import 'package:commet/ui/organisms/space_summary/space_summary.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/ui/pages/main/room_primary_view.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MainPageViewDesktop extends StatelessWidget {
  const MainPageViewDesktop(this.state, {super.key});
  final MainPageState state;

  String get directMessagesListHeaderDesktop => Intl.message(
        "Direct Messages",
        desc: "The header for the direct messages list on desktop",
        name: "directMessagesListHeaderDesktop",
      );

  @override
  Widget build(BuildContext context) {
    return tiamat.Foundation(
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tile(
                            caulkPadTop: true,
                            caulkPadRight: true,
                            caulkClipTopRight: true,
                            caulkClipBottomRight: true,
                            caulkBorderRight: true,
                            mode: TileType.surfaceDim,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                              child: ScaledSafeArea(
                                bottom: false,
                                child: SideNavigationBar(
                                  currentUser: state.currentUser,
                                  extraEntryBuilders: [
                                    (width) {
                                      return SidebarCallsList(
                                        state.clientManager.callManager,
                                        width,
                                      );
                                    },
                                  ],
                                  onSpaceSelected: (space) {
                                    state.selectSpace(space);
                                  },
                                  onHomeSelected: () {
                                    state.selectHome();
                                  },
                                  clearSpaceSelection: () {
                                    state.clearSpaceSelection();
                                  },
                                  onDirectMessageSelected: (room) {
                                    state.selectHome();
                                    state.selectRoom(room);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: tiamat.Tile.surfaceContainer(
                                caulkClipBottomLeft: true,
                                caulkClipTopRight: true,
                                caulkPadTop: true,
                                caulkClipBottomRight: true,
                                caulkClipTopLeft: true,
                                child: buildRoomPicker(context)),
                          ),
                        ],
                      ),
                    ),
                    tiamat.Tile.low(
                      caulkPadTop: true,
                      caulkClipTopRight: true,
                      caulkBorderTop: true,
                      caulkPadRight: Layout.mobile,
                      child: SizedBox(
                          height: 55,
                          child: currentUserPanel(state, context,
                              height: 55, avatarRadius: 16)),
                    ),
                  ],
                ),
              ),
              Expanded(child: mainView(context)),
            ],
          ),
          if (state.currentRoom != null)
            DragDropFileTarget(
              onDropComplete: (details) {
                EventBus.onFileDropped.add(details);
              },
            ),
          const BackgroundTaskViewContainer(),
        ],
      ),
    );
  }

  static Widget currentUserPanel(MainPageState state, BuildContext context,
      {double height = 50, double avatarRadius = 12}) {
    Profile? current = state.currentUser;

    if (clientManager!.clients.length == 1) {
      current = clientManager!.clients.first.self;
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Container(
                child: AdaptiveContextMenu(
              modal: true,
              items: [
                if (clientManager!.clients.length > 1)
                  tiamat.ContextMenuItem(
                      text: "Mix Accounts",
                      onPressed: () {
                        EventBus.setFilterClient.add(null);
                        preferences.filterClient.set(null);
                      }),
                if (clientManager!.clients.length > 1)
                  ...clientManager!.clients
                      .map((i) => tiamat.ContextMenuItem(
                          text: i.self!.identifier,
                          onPressed: () {
                            print("Setting filter client");
                            EventBus.setFilterClient.add(i);
                            preferences.filterClient.set(i.identifier);
                          }))
                      .toList()
              ],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  spacing: 8,
                  children: [
                    if (current != null)
                      tiamat.Avatar(
                        radius: avatarRadius,
                        image: current.avatar,
                        placeholderColor: current.defaultColor,
                        placeholderText: current.displayName,
                      ),
                    if (current != null)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tiamat.Text.name(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: current.defaultColor,
                                current.displayName),
                            tiamat.Text.labelLow(
                              maxLines: 1,
                              current.identifier,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    if (current == null)
                      ...clientManager!.clients
                          .where((i) => i.self != null)
                          .map((i) => Padding(
                                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: tiamat.Avatar(
                                    radius: avatarRadius,
                                    placeholderColor: i.self!.defaultColor,
                                    placeholderText: i.self!.displayName,
                                    image: i.self!.avatar,
                                  ),
                                ),
                              ))
                  ],
                ),
              ),
            )),
          ),
          Row(
            children: [
              SizedBox(
                  width: height,
                  height: height,
                  child: tiamat.IconButton(
                    icon: Icons.settings,
                    size: height / 4,
                    onPressed: () {
                      NavigationUtils.navigateTo(
                          context, const AppSettingsPage());
                    },
                  ))
            ],
          )
        ],
      )),
    );
  }

  SizedBox spaceRoomSelector(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          SpaceHeader(
            state.currentSpace!,
            onTap: state.clearRoomSelection,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLow,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SpaceViewer(
                state.currentSpace!,
                key: ValueKey(
                  "space-view-key-${state.currentSpace!.localId}",
                ),
                onRoomSelected: (room, {bool bypassSpecialRoomType = false}) {
                  state.selectRoom(room,
                      bypassSpecialRoomType: bypassSpecialRoomType);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget homeView() {
    return Row(
      children: [
        if (state.currentRoom == null)
          Expanded(
            child: Tile(
              caulkPadLeft: true,
              caulkClipTopLeft: true,
              caulkClipBottomLeft: true,
              caulkPadTop: true,
              caulkPadBottom: true,
              child: HomeScreen(
                clientManager: state.clientManager,
                filterClient: state.filterClient,
              ),
            ),
          ),
        if (state.currentRoom != null) roomChatView(),
      ],
    );
  }

  Widget roomChatView() {
    return Expanded(
      key: ValueKey("room-chat-view-${state.currentRoom!.localId}"),
      child: Column(
        children: [
          Tile.low(
            caulkPadBottom: true,
            caulkPadLeft: true,
            caulkClipBottomLeft: true,
            caulkBorderLeft: true,
            caulkBorderBottom: true,
            child: ScaledSafeArea(
              top: true,
              bottom: false,
              child: SizedBox(
                height: 50,
                child: RoomHeader(
                  state.currentRoom!,
                  onTap: state.currentRoom?.permissions.canEditAnything == true
                      ? () => state.navigateRoomSettings()
                      : null,
                  menu:
                      RoomQuickAccessMenuViewDesktop(room: state.currentRoom!),
                ),
              ),
            ),
          ),
          Expanded(
            child: Flex(
              direction: Axis.horizontal,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Tile(
                    caulkPadLeft: true,
                    caulkClipTopLeft: true,
                    caulkClipTopRight: true,
                    caulkBorderRight: true,
                    caulkPadBottom: true,
                    caulkClipBottomLeft: true,
                    caulkClipBottomRight: true,
                    caulkBorderLeft: true,
                    child: RoomPrimaryView(state.currentRoom!,
                        bypassSpecialRoomTypes: state.showAsTextRoom),
                  ),
                ),
                RoomSidePanel(
                  key: ValueKey(
                    "room-sidepanel-key-${state.currentRoom!.localId}",
                  ),
                  state: state,
                  builder: (state, child) {
                    Widget result = Tile.surfaceContainer(
                      caulkPadLeft: true,
                      caulkPadBottom: true,
                      caulkClipBottomLeft: true,
                      caulkClipTopLeft: true,
                      child: child,
                    );

                    if (state == SidePanelState.thread ||
                        state == SidePanelState.calendar) {
                      result = Flexible(child: result);
                    }

                    return result;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRoomPicker(BuildContext context) {
    if (state.currentSpace == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.labelLow(
                  directMessagesListHeaderDesktop,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.IconButton(
                  icon: Icons.add,
                  onPressed: () {
                    state.searchUserToDm();
                  },
                ),
              ),
            ],
          ),
          Flexible(
            child: DirectMessageList(
              filterClient: state.filterClient,
              directMessages: state.clientManager.directMessages,
              onSelected: (room) => state.selectRoom(room),
            ),
          ),
        ],
      );
    } else {
      return spaceRoomSelector(context);
    }
  }

  Widget mainView(BuildContext context) {
    if (state.currentView == MainPageSubView.home)
      return Flexible(child: homeView());
    if (state.currentRoom != null && state.currentView != MainPageSubView.home)
      return roomChatView();
    if (state.currentSpace != null && state.currentRoom == null)
      return Expanded(
        child: Tile(
          caulkPadTop: true,
          caulkPadBottom: true,
          caulkPadLeft: true,
          caulkClipTopLeft: true,
          caulkBorderLeft: true,
          caulkClipBottomLeft: true,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SpaceSummary(
                key: ValueKey(
                  "space-summary-key-${state.currentSpace!.localId}",
                ),
                space: state.currentSpace!,
                onRoomTap: (room) => state.selectRoom(room),
                onSpaceTap: (space) => state.selectSpace(space),
                onLeaveRoom: state.clearRoomSelection,
              ),
            ],
          ),
        ),
      );

    return Placeholder();
  }
}
