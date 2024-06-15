import 'package:commet/ui/atoms/drag_drop_file_target.dart';

import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/organisms/background_task_view/background_task_view_container.dart';
import 'package:commet/ui/organisms/home_screen/home_screen.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/organisms/space_summary/space_summary.dart';
import 'package:commet/ui/pages/main/main_page.dart';
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
                    onSpaceSelected: (index) {
                      state.selectSpace(state.clientManager.spaces[index]);
                    },
                    onHomeSelected: () {
                      state.selectHome();
                    },
                    clearSpaceSelection: () {
                      state.clearSpaceSelection();
                    },
                  ),
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
                          onRoomTap: (room) => state.selectRoom(room)),
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
                  child: SpaceViewer(
                state.currentSpace!,
                key: ValueKey("space-view-key-${state.currentSpace!.localId}"),
                onRoomInsert: state.currentSpace!.onRoomAdded,
                onRoomSelected: (index) {
                  state.selectRoom(state.currentSpace!.rooms[index]);
                },
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
                        clientManager: state.clientManager,
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
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Tile(
                    caulkPadLeft: true,
                    caulkClipTopLeft: true,
                    caulkClipTopRight: true,
                    caulkBorderRight: true,
                    caulkPadBottom: true,
                    caulkClipBottomLeft: true,
                    caulkClipBottomRight: true,
                    caulkBorderLeft: true,
                    child: Chat(
                      state.currentRoom!,
                      key: ValueKey(
                          "room-timeline-key-${state.currentRoom!.localId}"),
                    ),
                  ),
                ),
                if (state.currentThreadId != null)
                  Flexible(
                    child: Tile(
                      caulkPadLeft: true,
                      caulkClipTopLeft: true,
                      caulkClipBottomLeft: true,
                      caulkPadBottom: true,
                      child: Stack(
                        children: [
                          Chat(
                            state.currentRoom!,
                            threadId: state.currentThreadId,
                            key: ValueKey(
                                "room-timeline-key-${state.currentRoom!.localId}_thread_${state.currentThreadId!}"),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: tiamat.CircleButton(
                                icon: Icons.close,
                                onPressed: () => EventBus.closeThread.add(null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.currentThreadId == null)
                  Tile.surfaceContainer(
                    caulkPadLeft: true,
                    caulkClipTopLeft: true,
                    caulkClipBottomLeft: true,
                    caulkPadBottom: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: SizedBox(
                          width: 200,
                          child: RoomMembersListWidget(state.currentRoom!)),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
