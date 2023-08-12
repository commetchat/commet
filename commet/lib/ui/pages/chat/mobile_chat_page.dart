// ignore_for_file: prefer_const_constructors

import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';

import 'package:flutter/services.dart' as services;

import '../../../client/room.dart';

import '../../atoms/room_header.dart';
import '../../atoms/space_header.dart';
import '../../molecules/message_input.dart';
import '../../molecules/overlapping_panels.dart';
import '../../molecules/read_indicator.dart';
import '../../molecules/space_viewer.dart';
import '../../molecules/user_list.dart';
import '../../molecules/user_panel.dart';
import '../../organisms/side_navigation_bar.dart';

import 'package:flutter/material.dart' as m;

import '../../organisms/space_summary/space_summary.dart';

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

  static const Key homeRoomsList = ValueKey("MOBILE_HOME_ROOMS_LIST");
  static const Key directRoomsList = ValueKey("MOBILE_DIRECT_ROOMS_LIST");

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
            onDirectMessagesSelected: () {
              widget.state.selectDirectMessages();
            },
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
        if (widget.state.selectedView == SubView.home) homeView(),
        if (widget.state.selectedView == SubView.directMessages)
          directMessagesView(),
        if (widget.state.selectedView == SubView.space &&
            widget.state.selectedSpace != null)
          spaceRoomSelector(newContext),
      ],
    );
  }

  Widget mainPanel() {
    if (widget.state.selectedSpace != null &&
        widget.state.selectedRoom == null) {
      return Tile(
        child: ListView(children: [
          SpaceSummary(
            key: widget.state.selectedSpace!.key,
            space: widget.state.selectedSpace!,
            onRoomTap: (room) {
              widget.state.selectRoom(room);
            },
          ),
        ]),
      );
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
              widget.state.selectedRoom!,
              key: widget.state.selectedRoom!.key,
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
            padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
            child: DirectMessageList(
              key: directRoomsList,
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

  Widget homeView() {
    return Flexible(
      child: Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
            child: DirectMessageList(
              key: homeRoomsList,
              directMessages: widget.state.clientManager.singleRooms,
              onSelected: (index) {
                setState(() {
                  selectRoom(widget.state.clientManager.singleRooms[index]);
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
                onRoomSelectionChanged:
                    widget.state.onRoomSelectionChanged.stream,
                onRoomSelected: (index) async {
                  selectRoom(widget.state.selectedSpace!.rooms[index]);
                },
              ),
            )),
            Tile.low2(
              child: SizedBox(
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: UserPanelView(
                    displayName:
                        widget.state.selectedSpace!.client.user!.displayName,
                    avatar: widget.state.selectedSpace!.client.user!.avatar,
                    detail: widget.state.selectedSpace!.client.user!.detail,
                  ),
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
                  height: 50,
                  child: RoomHeader(
                    widget.state.selectedRoom!,
                    onTap: widget.state.selectedRoom?.permissions
                                .canEditAnything ==
                            true
                        ? () => widget.state.navigateRoomSettings()
                        : null,
                  )),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: TimelineViewer(
                      doMessageOverlayMenu: false,
                      markAsRead:
                          widget.state.selectedRoom!.timeline!.markAsRead,
                      key: widget
                          .state.timelines[widget.state.selectedRoom!.localId],
                      timeline: widget.state.selectedRoom!.timeline!,
                      onEventLongPress: showMessageMenu,
                    )),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: MessageInput(
                          key: messageInput,
                          isRoomE2EE: widget.state.selectedRoom!.isE2EE,
                          readIndicator: ReadIndicator(
                            room: widget.state.selectedRoom!,
                            initialList:
                                widget.state.selectedRoom?.timeline?.receipts,
                          ),
                          onSendMessage: (message) {
                            widget.state.sendMessage(message);
                            return MessageInputSendResult.success;
                          },
                          relatedEventBody: widget.state.interactingEvent?.body,
                          attachments: widget.state.attachments,
                          isProcessing: widget.state.processing,
                          setInputText: widget.state.setMessageInputText.stream,
                          relatedEventSenderName:
                              widget.state.relatedEventSenderName,
                          relatedEventSenderColor:
                              widget.state.relatedEventSenderColor,
                          interactionType: widget.state.interactionType,
                          addAttachment: widget.state.addAttachment,
                          onTextUpdated: widget.state.onInputTextUpdated,
                          typingUsernames: widget
                              .state.selectedRoom!.typingPeers
                              .map((e) => e.displayName)
                              .toList(),
                          removeAttachment: widget.state.removeAttachment,
                          focusKeyboard:
                              widget.state.onFocusMessageInput.stream,
                          availibleEmoticons: widget.state.selectedRoom!
                              .roomEmoticons!.availableEmoji,
                          availibleStickers: widget.state.selectedRoom!
                              .roomEmoticons!.availableStickers,
                          sendGif: widget.state.sendGif,
                          sendSticker: widget.state.sendSticker,
                          cancelReply: () {
                            widget.state.setInteractingEvent(
                              null,
                            );
                          }),
                    )
                  ],
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

  void showMessageMenu(TimelineEvent event) {
    m.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          m.Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
                controller: scrollController,
                child: buildMessageMenu(context, event));
          },
        );
      },
    );
  }

  void showReactionMenu(TimelineEvent event) {
    m.showModalBottomSheet(
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return SizedBox(
              height: 700,
              child: EmojiPicker(
                widget.state.selectedRoom!.roomEmoticons!.availableEmoji,
                size: 48,
                packButtonSize: 40,
                onEmoticonPressed: (emoticon) {
                  widget.state.addReaction(event, emoticon);
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget buildMessageMenu(BuildContext context, TimelineEvent event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    m.Colors.white,
                    m.Colors.transparent,
                  ],
                  stops: [0.90, 1.0],
                ).createShader(bounds);
              },
              child: SizedBox(
                height: 100,
                child: Center(
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      child: TimelineEventView(
                          event: event,
                          timeline: widget.state.selectedRoom!.timeline!),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: TextButton(
                "Reply",
                icon: m.Icons.reply,
                onTap: () {
                  widget.state.setInteractingEvent(event,
                      type: EventInteractionType.reply);
                  Navigator.pop(context);
                },
              ),
            ),
            SizedBox(
              height: 50,
              child: TextButton(
                "Add Reaction",
                icon: m.Icons.add_reaction_rounded,
                onTap: () {
                  Navigator.pop(context);
                  showReactionMenu(event);
                },
              ),
            ),
            if (canEditMessage(event))
              SizedBox(
                height: 50,
                child: TextButton(
                  "Edit Message",
                  icon: m.Icons.edit,
                  onTap: () {
                    widget.state.setInteractingEvent(event,
                        type: EventInteractionType.edit);
                    Navigator.pop(context);
                  },
                ),
              ),
            if (canDeleteMessage(event))
              SizedBox(
                height: 50,
                child: TextButton(
                  "Delete Message",
                  icon: m.Icons.delete_forever,
                  onTap: () {
                    widget.state.selectedRoom?.timeline
                        ?.deleteEvent(event.eventId);
                    Navigator.pop(context);
                  },
                ),
              ),
            SizedBox(
              height: 50,
              child: TextButton(
                "Copy Text",
                icon: m.Icons.copy,
                onTap: () {
                  services.Clipboard.setData(
                      services.ClipboardData(text: event.body!));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool canEditMessage(TimelineEvent event) {
    if (widget.state.selectedRoom?.permissions.canUserEditMessages != true)
      return false;

    if (event.senderId != widget.state.selectedRoom!.client.user!.identifier)
      return false;

    if (event.type != EventType.message) return false;

    return true;
  }

  bool canDeleteMessage(TimelineEvent event) {
    if (widget.state.selectedRoom?.permissions.canUserDeleteMessages != true)
      return false;

    if (event.senderId != widget.state.selectedRoom!.client.user!.identifier)
      return false;

    if (event.type != EventType.message) return false;

    return true;
  }
}
