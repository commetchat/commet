import 'package:commet/ui/atoms/drag_drop_file_target.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/split_timeline_viewer.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';

import '../../organisms/space_summary/space_summary.dart';

class DesktopChatPageView extends StatefulWidget {
  const DesktopChatPageView({required this.state, super.key});
  final ChatPageState state;
  @override
  State<DesktopChatPageView> createState() => _DesktopChatPageViewState();
}

class _DesktopChatPageViewState extends State<DesktopChatPageView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tile.low4(
              child: SideNavigationBar(
                onSpaceSelected: (index) {
                  widget.state
                      .selectSpace(widget.state.clientManager.spaces[index]);
                },
                onHomeSelected: () {
                  widget.state.selectHome();
                },
                clearSpaceSelection: () {
                  widget.state.clearSpaceSelection();
                },
              ),
            ),
            if (widget.state.homePageSelected) homePageView(),
            if (!widget.state.homePageSelected &&
                widget.state.selectedSpace != null)
              spaceRoomSelector(),
            if (widget.state.selectedRoom != null) roomChatView(),
            if (widget.state.selectedSpace != null &&
                widget.state.selectedRoom == null)
              Expanded(
                child: Tile(
                  child: ListView(children: [
                    SpaceSummary(
                      key: widget.state.selectedSpace!.key,
                      space: widget.state.selectedSpace!,
                      onRoomTap: (room) {
                        widget.state.selectRoom(room);
                      },
                    ),
                  ]),
                ),
              ),
          ],
        ),
        if (widget.state.selectedRoom != null)
          DragDropFileTarget(
            onDropComplete: (details) {
              for (var file in details.files) {
                debugPrint(file.path);
              }
            },
          )
      ],
    );
  }

  Widget homePageView() {
    return Tile.low1(
      child: SizedBox(
        width: 250,
        child: DirectMessageList(
          directMessages: widget.state.clientManager.directMessages,
          onSelected: (index) {
            setState(() {
              widget.state
                  .selectRoom(widget.state.clientManager.directMessages[index]);
            });
          },
        ),
      ),
    );
  }

  Flexible roomChatView() {
    return Flexible(
        child: Tile(
      borderLeft: true,
      child: Column(
        children: [
          SizedBox(
              height: 50,
              child: RoomHeader(
                widget.state.selectedRoom!,
                onTap: widget.state.selectedRoom?.permissions.canEditAnything ==
                        true
                    ? () => widget.state.navigateRoomSettings()
                    : null,
              )),
          Flexible(
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                          child: SplitTimelineViewer(
                        key: widget.state
                            .timelines[widget.state.selectedRoom!.localId],
                        timeline: widget.state.selectedRoom!.timeline!,
                      )),
                      Tile(
                        borderTop: true,
                        child: MessageInput(
                          onSendMessage: (message) {
                            widget.state.selectedRoom!.sendMessage(message);
                            return MessageInputSendResult.clearText;
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                    width: 250,
                    child: PeerList(
                      widget.state.selectedRoom!.members,
                      key: widget.state.selectedRoom!.key,
                    )),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  SizedBox spaceRoomSelector() {
    return SizedBox(
        width: 250,
        child: Tile.low1(
          child: Column(
            children: [
              SizedBox(
                  height: 80,
                  child: Tile.low2(
                    borderBottom: true,
                    child: SpaceHeader(
                      widget.state.selectedSpace!,
                      onTap: widget.state.clearRoomSelection,
                      backgroundColor: Theme.of(context)
                          .extension<ExtraColors>()!
                          .surfaceLow1,
                    ),
                  )),
              Expanded(
                  child: SpaceViewer(
                widget.state.selectedSpace!,
                key: widget.state.selectedSpace!.key,
                onRoomSelectionChanged:
                    widget.state.onRoomSelectionChanged.stream,
                onRoomInsert: widget.state.selectedSpace!.onRoomAdded.stream,
                onRoomSelected: (index) {
                  widget.state
                      .selectRoom(widget.state.selectedSpace!.rooms[index]);
                },
              )),
              Tile.low2(
                child: SizedBox(
                  height: 65,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: UserPanel(
                      displayName:
                          widget.state.selectedSpace!.client.user!.displayName,
                      avatar: widget.state.selectedSpace!.client.user!.avatar,
                      detail: widget.state.selectedSpace!.client.user!.detail,
                      color: widget.state.selectedSpace!.client.user!.color,
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
