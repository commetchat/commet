import 'package:commet/client/client_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/atoms/drag_drop_file_target.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart';
import '../../../client/client.dart';

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
          children: [
            SideNavigationBar(
              onSpaceSelected: (index) {
                widget.state.selectSpace(widget.state.clientManager.spaces[index]);
              },
              onHomeSelected: () {
                widget.state.selectHome();
              },
            ),
            if (widget.state.homePageSelected) homePageView(),
            if (!widget.state.homePageSelected && widget.state.selectedSpace != null) spaceRoomSelector(),
            if (widget.state.selectedRoom != null) roomChatView(),
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
              widget.state.selectRoom(widget.state.clientManager.directMessages[index]);
            });
          },
        ),
      ),
    );
  }

  Flexible roomChatView() {
    return Flexible(
        child: Column(
      children: [
        SizedBox(height: s(50), child: RoomHeader(widget.state.selectedRoom!)),
        Flexible(
          child: Row(
            children: [
              Flexible(
                child: Tile(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                          child: TimelineViewer(
                        key: widget.state.timelines[widget.state.selectedRoom!.identifier],
                        timeline: widget.state.selectedRoom!.timeline!,
                      )),
                      MessageInput(
                        onSendMessage: (message) {
                          widget.state.selectedRoom!.sendMessage(message);
                          return MessageInputSendResult.clearText;
                        },
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                  width: s(250),
                  child: PeerList(
                    widget.state.selectedRoom!.members,
                    key: widget.state.selectedRoom!.key,
                  )),
            ],
          ),
        ),
      ],
    ));
  }

  SizedBox spaceRoomSelector() {
    return SizedBox(
        width: s(250),
        child: Tile.low1(
          child: Column(
            children: [
              SizedBox(height: s(50), child: SpaceHeader(widget.state.selectedSpace!)),
              Expanded(
                  child: SpaceViewer(
                widget.state.selectedSpace!,
                key: widget.state.selectedSpace!.key,
                onRoomInsert: widget.state.selectedSpace!.onRoomAdded.stream,
                onRoomSelected: (index) {
                  widget.state.selectRoom(widget.state.selectedSpace!.rooms[index]);
                },
              )),
              Tile.low2(
                child: SizedBox(
                  height: s(65),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: UserPanel(
                      displayName: widget.state.selectedSpace!.client.user!.displayName,
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
