import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/floating_tile.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/overlapping_panels.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/organisms/background_task_view/background_task_view.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/home_screen/home_screen.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/organisms/space_summary/space_summary.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:flutter/material.dart' as material;

class MainPageViewMobile extends StatefulWidget {
  const MainPageViewMobile(this.state, {super.key});
  final MainPageState state;

  @override
  State<MainPageViewMobile> createState() => _MainPageViewMobileState();
}

class _MainPageViewMobileState extends State<MainPageViewMobile> {
  late GlobalKey<OverlappingPanelsState> panelsKey;
  bool shouldMainIgnoreInput = false;
  double height = -1;

  String get directMessagesListHeaderMobile => Intl.message("Direct Messages",
      desc: "The header for the direct messages list on desktop",
      name: "directMessagesListHeaderMobile");

  GlobalKey mainPanelKey = GlobalKey();

  @override
  void initState() {
    panelsKey = GlobalKey<OverlappingPanelsState>();
    super.initState();
  }

  bool canPop() {
    switch (panelsKey.currentState?.currentSide) {
      case RevealSide.right:
        return false;
      case RevealSide.main:
        return false;
      case RevealSide.left:
        return true;
      case null:
        //idk in what case this will ever happen...
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: canPop(),
        onPopInvoked: (didPop) {
          switch (panelsKey.currentState?.currentSide) {
            case RevealSide.right:
              panelsKey.currentState?.reveal(RevealSide.main);
            case RevealSide.main:
              panelsKey.currentState?.reveal(RevealSide.left);
            default:
              break;
          }
        },
        child: Tile.low4(
          child: OverlappingPanels(
              key: panelsKey,
              left: navigation(context),
              main: Container(
                child: shouldMainIgnoreInput
                    ? IgnorePointer(
                        child: Container(key: mainPanelKey, child: mainPanel()),
                      )
                    : Container(key: mainPanelKey, child: mainPanel()),
              ),
              onDragStart: () {},
              onSideChange: (side) {
                setState(() {
                  shouldMainIgnoreInput = side != RevealSide.main;
                });
              },
              right: widget.state.currentRoom != null ? userList() : null),
        ));
  }

  Widget navigation(BuildContext newContext) {
    return Tile.low4(
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: SafeArea(
              child: SideNavigationBar(
                currentUser: widget.state.getCurrentUser(),
                onSpaceSelected: (index) {
                  widget.state
                      .selectSpace(widget.state.clientManager.spaces[index]);
                },
                clearSpaceSelection: () {
                  widget.state.clearSpaceSelection();
                },
                onHomeSelected: () {
                  widget.state.selectHome();
                },
              ),
            ),
          ),
          if (widget.state.currentView == MainPageSubView.home)
            directMessagesView(),
          if (widget.state.currentView == MainPageSubView.space &&
              widget.state.currentSpace != null)
            spaceRoomSelector(newContext),
          if (backgroundTaskManager.tasks.isNotEmpty)
            FloatingTile(
              child: BackgroundTaskView(backgroundTaskManager),
            )
        ],
      ),
    );
  }

  Widget mainPanel() {
    if (widget.state.currentSpace != null && widget.state.currentRoom == null) {
      return Tile(
        child: SafeArea(
          child: ListView(children: [
            SpaceSummary(
              key: ValueKey(
                  "space-summary-key-${widget.state.currentSpace!.localId}"),
              space: widget.state.currentSpace!,
              onRoomTap: (room) {
                widget.state.selectRoom(room);
              },
            ),
          ]),
        ),
      );
    }

    if (widget.state.currentRoom != null) {
      return Tile(
        child: material.Scaffold(
          backgroundColor: material.Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: RoomHeader(
                    widget.state.currentRoom!,
                    onTap:
                        widget.state.currentRoom?.permissions.canEditAnything ==
                                true
                            ? () => widget.state.navigateRoomSettings()
                            : null,
                  ),
                ),
                Flexible(
                  child: Chat(
                    widget.state.currentRoom!,
                    key: ValueKey(
                        "room-timeline-key-${widget.state.currentRoom!.localId}"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tile(
        child: SafeArea(
            child: HomeScreen(clientManager: widget.state.clientManager)));
  }

  Widget userList() {
    if (widget.state.currentRoom != null) {
      return Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: RoomMembersListWidget(
              widget.state.currentRoom!,
              key: ValueKey(
                  "room-participant-list-key-${widget.state.currentRoom!.localId}"),
            ),
          ),
        ),
      );
    }
    return const Placeholder();
  }

  Widget directMessagesView() {
    return Flexible(
      child: Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tiamat.Text.labelLow(directMessagesListHeaderMobile),
                ),
                Flexible(
                  child: DirectMessageList(
                    clientManager: widget.state.clientManager,
                    onSelected: (room) {
                      setState(() {
                        selectRoom(room);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget spaceRoomSelector(BuildContext newContext) {
    return Flexible(
      child: Tile.low1(
        child: Column(
          children: [
            SpaceHeader(
              widget.state.currentSpace!,
              backgroundColor: material.Theme.of(context)
                  .extension<ExtraColors>()!
                  .surfaceLow1,
              onTap: clearSelectedRoom,
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: SpaceViewer(
                widget.state.currentSpace!,
                key: ValueKey(
                    "space-view-key-${widget.state.currentSpace!.localId}"),
                onRoomInsert: widget.state.currentSpace!.onRoomAdded,
                onRoomSelected: (index) async {
                  selectRoom(widget.state.currentSpace!.rooms[index]);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void clearSelectedRoom() {
    Future.delayed(const Duration(milliseconds: 125)).then((value) {
      panelsKey.currentState!.reveal(RevealSide.main);
      setState(() {
        shouldMainIgnoreInput = false;
      });
    });
    widget.state.clearRoomSelection();
  }

  void selectRoom(Room room) {
    panelsKey.currentState!.reveal(RevealSide.main);
    setState(() {
      shouldMainIgnoreInput = false;
    });

    widget.state.selectRoom(room);
  }
}
