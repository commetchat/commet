import 'dart:math';

import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/overlapping_panels.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/organisms/background_task_view/background_task_view_container.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/home_screen/home_screen.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/ui/organisms/space_summary/space_summary.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/foundation.dart';
import 'package:tiamat/atoms/tile.dart';
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
    EventBus.openThread.stream.listen((event) {
      panelsKey.currentState?.reveal(RevealSide.right);
    });
    EventBus.closeThread.stream.listen((event) {
      panelsKey.currentState?.reveal(RevealSide.main);
    });

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
        child: Foundation(
            child: OverlappingPanels(
          key: panelsKey,
          onDragStart: () {},
          onSideChange: (side) {
            setState(() {
              shouldMainIgnoreInput = side != RevealSide.main;
            });
          },
          left: navigation(context),
          main: Foundation(
              child: IgnorePointer(
            ignoring: shouldMainIgnoreInput,
            child: Container(key: mainPanelKey, child: mainPanel()),
          )),
          right: rightPanel(context),
        )));
  }

  Widget? rightPanel(BuildContext context) {
    if (widget.state.currentThreadId != null &&
        widget.state.currentRoom != null) {
      return Tile(
        child: keyboardAdaptor(
          Stack(
            children: [
              Chat(
                widget.state.currentRoom!,
                threadId: widget.state.currentThreadId,
                key: ValueKey(
                    "room-timeline-key-${widget.state.currentRoom!.localId}_thread_${widget.state.currentThreadId!}"),
              ),
              ScaledSafeArea(
                child: Align(
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
              ),
            ],
          ),
        ),
      );
    }

    if (widget.state.currentRoom != null) {
      return userList();
    }

    return null;
  }

  Widget navigation(BuildContext newContext) {
    return Row(
      children: [
        Tile(
          caulkPadRight: true,
          caulkClipTopRight: true,
          caulkClipBottomRight: true,
          caulkBorderRight: true,
          mode: TileType.surfaceDim,
          child: ScaledSafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
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
                onDirectMessageSelected: (room) {
                  widget.state.selectHome();
                  widget.state.selectRoom(room);
                  panelsKey.currentState?.reveal(RevealSide.main);
                },
              ),
            ),
          ),
        ),
        if (widget.state.currentView == MainPageSubView.home)
          directMessagesView(),
        if (widget.state.currentView == MainPageSubView.space &&
            widget.state.currentSpace != null)
          spaceRoomSelector(newContext),
        const BackgroundTaskViewContainer()
      ],
    );
  }

  Widget keyboardAdaptor(Widget child, {bool ignore = false}) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    return ScaledSafeArea(
        bottom: false,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, offset), child: child));
  }

  Widget mainPanel() {
    if (widget.state.currentSpace != null && widget.state.currentRoom == null) {
      return Tile(
        child: ScaledSafeArea(
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
      var scaledQuery = MediaQuery.of(context).scale();
      var offset = scaledQuery.viewInsets.bottom;
      if (offset == 0) {
        offset = scaledQuery.padding.bottom;
      }
      return Tile(
        child: keyboardAdaptor(
          Column(
            children: [
              Tile.low(
                caulkClipBottomRight: true,
                caulkClipBottomLeft: true,
                caulkBorderBottom: true,
                child: SizedBox(
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
      );
    }

    return Tile(
        child: ScaledSafeArea(
            child: HomeScreen(clientManager: widget.state.clientManager)));
  }

  Widget userList() {
    if (widget.state.currentRoom != null) {
      return Tile.surfaceContainer(
        caulkPadLeft: true,
        caulkClipTopLeft: true,
        caulkClipBottomLeft: true,
        caulkBorderLeft: true,
        caulkBorderTop: true,
        caulkBorderBottom: true,
        child: ScaledSafeArea(
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
      child: Tile.surfaceContainer(
        caulkClipTopLeft: true,
        caulkClipBottomLeft: true,
        caulkPadRight: true,
        caulkClipTopRight: true,
        caulkClipBottomRight: true,
        child: ScaledSafeArea(
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
                    directMessages: widget.state.clientManager.directMessages,
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
      child: Tile.surfaceContainer(
        caulkClipTopLeft: true,
        caulkClipBottomLeft: true,
        caulkPadRight: true,
        caulkClipTopRight: true,
        caulkClipBottomRight: true,
        child: Column(
          children: [
            SpaceHeader(
              widget.state.currentSpace!,
              backgroundColor:
                  material.Theme.of(context).colorScheme.surfaceContainerLow,
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
