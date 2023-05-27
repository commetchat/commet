import 'dart:typed_data';

import 'package:commet/ui/atoms/drag_drop_file_target.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/read_indicator.dart';
import 'package:commet/ui/molecules/split_timeline_viewer.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';

import 'package:mime/mime.dart' as mime;

import '../../../client/attachment.dart';
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
          DragDropFileTarget(onDropComplete: onFileDrop)
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
                        markAsRead:
                            widget.state.selectedRoom!.timeline!.markAsRead,
                        setReplyingEvent: (event) => widget.state
                            .setInteractingEvent(event,
                                type: EventInteractionType.reply),
                        setEditingEvent: (event) => widget.state
                            .setInteractingEvent(event,
                                type: EventInteractionType.edit),
                      )),
                      Tile(
                        borderTop: true,
                        child: MessageInput(
                          isRoomE2EE: widget.state.selectedRoom!.isE2EE,
                          focusKeyboard:
                              widget.state.onFocusMessageInput.stream,
                          attachments: widget.state.attachments,
                          readIndicator: ReadIndicator(
                            initialList:
                                widget.state.selectedRoom?.timeline?.receipts,
                          ),
                          interactionType: widget.state.interactionType,
                          onSendMessage: (message) {
                            widget.state.sendMessage(message);
                            return MessageInputSendResult.success;
                          },
                          addAttachment: widget.state.addAttachment,
                          removeAttachment: widget.state.removeAttachment,
                          isProcessing: widget.state.processing,
                          relatedEventBody: widget.state.interactingEvent?.body,
                          relatedEventSenderName:
                              widget.state.interactingEvent?.sender.displayName,
                          relatedEventSenderColor:
                              widget.state.interactingEvent?.sender.color,
                          setInputText: widget.state.setMessageInputText.stream,
                          editLastMessage: widget.state.editLastMessage,
                          cancelReply: () {
                            widget.state.setInteractingEvent(null);
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

  void onFileDrop(DropDoneDetails details) async {
    const int fiftyMb = 52428800;

    for (var file in details.files) {
      debugPrint(file.path);

      var length = await file.length();

      Uint8List? data;
      String? name = file.name;
      String? mimeType = mime.lookupMimeType(file.path, headerBytes: data);

      if (length < fiftyMb) {
        data = await file.readAsBytes();
      }

      var attachment = PendingFileAttachment(
          name: name, path: file.path, data: data, mimeType: mimeType);

      widget.state.addAttachment(attachment);
    }
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
