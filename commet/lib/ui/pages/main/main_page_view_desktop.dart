import 'package:commet/ui/atoms/drag_drop_file_target.dart';

import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/organisms/background_task_view/background_task_view_container.dart';
import 'package:commet/ui/organisms/call_view/call.dart';
import 'package:commet/ui/organisms/home_screen/home_screen.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu_desktop.dart';
import 'package:commet/ui/organisms/room_side_panel/room_side_panel.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/ui/organisms/sidebar_call_icon/sidebar_calls_list.dart';
import 'package:commet/ui/organisms/space_summary/space_summary.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/ui/pages/main/room_primary_view.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MainPageViewDesktop extends StatelessWidget {
  const MainPageViewDesktop(this.state, {super.key});
  final MainPageState state;

  String get directMessagesListHeaderDesktop => Intl.message("Direct Messages",
      desc: "The header for the direct messages list on desktop",
      name: "directMessagesListHeaderDesktop");

  @override
  Widget build(BuildContext context) {
    return tiamat.Foundation(
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Tile(
                caulkPadTop: true,
                caulkPadBottom: true,
                caulkPadRight: true,
                caulkClipTopRight: true,
                caulkClipBottomRight: true,
                caulkBorderRight: true,
                mode: TileType.surfaceDim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: SideNavigationBar(
                      currentUser: state.currentUser,
                      extraEntryBuilders: [
                        (width) {
                          return SidebarCallsList(
                              state.clientManager.callManager, width);
                        }
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
                      }),
                ),
              ),
              if (state.currentView == MainPageSubView.space &&
                  state.currentSpace != null)
                spaceRoomSelector(context),
              if (state.currentView == MainPageSubView.home)
                Expanded(child: homeView()),
              if (state.currentRoom != null &&
                  state.currentView != MainPageSubView.home)
                roomChatView(),
              if (state.currentSpace != null && state.currentRoom == null)
                Expanded(
                  child: Tile(
                    caulkPadTop: true,
                    caulkPadBottom: true,
                    caulkPadLeft: true,
                    caulkClipTopLeft: true,
                    caulkBorderLeft: true,
                    caulkClipBottomLeft: true,
                    child: ListView(children: [
                      SpaceSummary(
                        key: ValueKey(
                            "space-summary-key-${state.currentSpace!.localId}"),
                        space: state.currentSpace!,
                        onRoomTap: (room) => state.selectRoom(room),
                        onSpaceTap: (space) => state.selectSpace(space),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
          if (state.currentRoom != null)
            DragDropFileTarget(
              onDropComplete: (details) {
                EventBus.onFileDropped.add(details);
              },
            ),
          const BackgroundTaskViewContainer()
        ],
      ),
    );
  }

  SizedBox spaceRoomSelector(BuildContext context) {
    return SizedBox(
        width: 250,
        child: Tile.surfaceContainer(
          caulkPadTop: true,
          caulkPadBottom: true,
          caulkClipTopLeft: true,
          caulkClipTopRight: true,
          caulkClipBottomLeft: true,
          caulkClipBottomRight: true,
          child: Column(
            children: [
              SpaceHeader(
                state.currentSpace!,
                onTap: state.clearRoomSelection,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              Expanded(
                  child: SingleChildScrollView(
                child: SpaceViewer(
                  state.currentSpace!,
                  key:
                      ValueKey("space-view-key-${state.currentSpace!.localId}"),
                  onRoomSelected: (room) {
                    state.selectRoom(room);
                  },
                ),
              )),
            ],
          ),
        ));
  }

  Widget homeView() {
    return Row(
      children: [
        Tile.surfaceContainer(
          caulkClipTopLeft: true,
          caulkClipTopRight: true,
          caulkClipBottomRight: true,
          caulkClipBottomLeft: true,
          caulkPadTop: true,
          caulkPadBottom: true,
          caulkBorderRight: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
            child: SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        tiamat.Text.labelLow(directMessagesListHeaderDesktop),
                  ),
                  Flexible(
                    child: DirectMessageList(
                        directMessages: state.clientManager.directMessages,
                        onSelected: (room) => state.selectRoom(room)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.currentRoom == null)
          Expanded(
            child: Tile(
              caulkPadLeft: true,
              caulkClipTopLeft: true,
              caulkClipBottomLeft: true,
              caulkPadTop: true,
              caulkPadBottom: true,
              child: HomeScreen(clientManager: state.clientManager),
            ),
          ),
        if (state.currentRoom != null) roomChatView()
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
            child: SizedBox(
              height: 50,
              child: RoomHeader(
                state.currentRoom!,
                onTap: state.currentRoom?.permissions.canEditAnything == true
                    ? () => state.navigateRoomSettings()
                    : null,
                menu: RoomQuickAccessMenuViewDesktop(
                  room: state.currentRoom!,
                ),
              ),
            ),
          ),
          if (state.currentCall != null)
            Flexible(child: CallWidget(state.currentCall!)),
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
                    child: RoomPrimaryView(
                      state.currentRoom!,
                    ),
                  ),
                ),
                RoomSidePanel(
                    key: ValueKey(
                        "room-sidepanel-key-${state.currentRoom!.localId}"),
                    state: state,
                    builder: (state, child) {
                      Widget result = Tile.surfaceContainer(
                        caulkPadLeft: true,
                        caulkPadBottom: true,
                        caulkClipBottomLeft: true,
                        caulkClipTopLeft: true,
                        child: child,
                      );

                      if (state == SidePanelState.thread) {
                        result = Flexible(child: result);
                      }

                      return result;
                    })
              ],
            ),
          ),
        ],
      ),
    );
  }
}
