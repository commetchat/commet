// ignore_for_file: prefer_const_constructors

import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/split_timeline_viewer.dart';
import 'package:commet/ui/organisms/space_summary.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';

import '../../../client/room.dart';

import '../../atoms/room_header.dart';
import '../../atoms/space_header.dart';
import '../../molecules/message_input.dart';
import '../../molecules/overlapping_panels.dart';
import '../../molecules/space_viewer.dart';
import '../../molecules/user_list.dart';
import '../../molecules/user_panel.dart';
import '../../organisms/side_navigation_bar.dart';

import 'package:flutter/material.dart' as m;

class MobileChatPageView extends StatefulWidget {
  const MobileChatPageView({required this.state, super.key});
  final ChatPageState state;

  @override
  State<MobileChatPageView> createState() => _MobileChatPageViewState();
}

class _MobileChatPageViewState extends State<MobileChatPageView> {
  late GlobalKey<OverlappingPanelsState> panelsKey;
  late GlobalKey<MessageInputState> messageInput = GlobalKey();
  bool shouldMainIgnoreInput = false;
  double height = -1;

  @override
  void initState() {
    panelsKey = GlobalKey<OverlappingPanelsState>();
    super.initState();
  }

  @override
  Widget build(BuildContext newContext) {
    return OverlappingPanels(
        key: panelsKey,
        left: navigation(newContext),
        main: shouldMainIgnoreInput
            ? IgnorePointer(
                child: mainPanel(),
              )
            : mainPanel(),
        onDragStart: () {
          messageInput.currentState?.unfocus();
        },
        onSideChange: (side) {
          setState(() {
            shouldMainIgnoreInput = side != RevealSide.main;
          });
        },
        right: widget.state.selectedRoom != null ? userList() : null);
  }

  Widget navigation(BuildContext newContext) {
    return Row(
      children: [
        Tile.low4(
          child: SideNavigationBar(
            onHomeSelected: () {
              widget.state.selectHome();
            },
            onSpaceSelected: (index) {
              widget.state
                  .selectSpace(widget.state.clientManager.spaces[index]);
            },
            clearSpaceSelection: () {
              widget.state.clearSpaceSelection();
            },
          ),
        ),
        if (widget.state.homePageSelected) homePageView(),
        if (widget.state.homePageSelected == false &&
            widget.state.selectedSpace != null)
          spaceRoomSelector(newContext),
      ],
    );
  }

  Widget mainPanel() {
    if (widget.state.selectedSpace != null &&
        widget.state.selectedRoom == null) {
      return SpaceSummary(space: widget.state.selectedSpace!);
    }

    return timelineView();
  }

  Widget userList() {
    if (widget.state.selectedRoom != null) {
      return Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 20, 0, 0),
            child: PeerList(
              widget.state.selectedRoom!.members,
              key: widget.state.selectedRoom!.key,
            ),
          ),
        ),
      );
    }
    return const Placeholder();
  }

  Widget homePageView() {
    return Flexible(
      child: Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
            child: DirectMessageList(
              directMessages: widget.state.clientManager.directMessages,
              onSelected: (index) {
                setState(() {
                  selectRoom(widget.state.clientManager.directMessages[index]);
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget timelineView() {
    if (widget.state.selectedRoom != null) {
      return roomChatView();
    }

    return Container(
      color: m.Colors.red,
      child: const Placeholder(),
    );
  }

  Widget spaceRoomSelector(BuildContext newContext) {
    return Flexible(
      child: Tile.low1(
        child: Column(
          children: [
            SizedBox(
              height: 100.1,
              child: SpaceHeader(
                widget.state.selectedSpace!,
                backgroundColor: material.Theme.of(context)
                    .extension<ExtraColors>()!
                    .surfaceLow1,
                onTap: clearSelectedRoom,
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
              child: SpaceViewer(
                widget.state.selectedSpace!,
                key: widget.state.selectedSpace!.key,
                onRoomInsert: widget.state.selectedSpace!.onRoomAdded.stream,
                onRoomSelected: (index) async {
                  selectRoom(widget.state.selectedSpace!.rooms[index]);
                },
              ),
            )),
            Tile.low2(
              child: SizedBox(
                height: 70,
                child: UserPanel(
                  displayName:
                      widget.state.selectedSpace!.client.user!.displayName,
                  avatar: widget.state.selectedSpace!.client.user!.avatar,
                  detail: widget.state.selectedSpace!.client.user!.detail,
                  color: widget.state.selectedSpace!.client.user!.color,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget roomChatView() {
    return Tile(
      child: m.Scaffold(
        backgroundColor: m.Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                  height: 50, child: RoomHeader(widget.state.selectedRoom!)),
              Flexible(
                // We listen to this so that when the onscreen keyboard changes the size of view inset, we can offset the scroll position
                child: NotificationListener(
                  onNotification: (notification) {
                    var prevHeight = height;
                    height = MediaQuery.of(context).viewInsets.bottom;
                    if (prevHeight == -1) return true;

                    var diff = height - prevHeight;
                    if (diff <= 0) return true;

                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      var state = widget
                          .state
                          .timelines[widget.state.selectedRoom?.localId]
                          ?.currentState;
                      if (state != null) {
                        state.controller.jumpTo(state.controller.offset + diff);
                      }
                    });

                    return true;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                            child: SplitTimelineViewer(
                          key: widget.state
                              .timelines[widget.state.selectedRoom!.localId],
                          timeline: widget.state.selectedRoom!.timeline!,
                        )),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                          child: MessageInput(
                            key: messageInput,
                            onSendMessage: (message) {
                              widget.state.selectedRoom!.sendMessage(message);
                              return MessageInputSendResult.clearText;
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    Future.delayed(const Duration(milliseconds: 125)).then((value) {
      panelsKey.currentState!.reveal(RevealSide.main);
      setState(() {
        shouldMainIgnoreInput = false;
      });
    });

    widget.state.selectRoom(room);
  }
}
