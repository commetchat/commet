import 'package:commet/ui/molecules/direct_message_list.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart';

import '../../../client/client_manager.dart';
import '../../../client/room.dart';
import '../../../client/space.dart';
import '../../../config/app_config.dart';

import '../../atoms/room_header.dart';
import '../../atoms/space_header.dart';
import '../../molecules/message_input.dart';
import '../../molecules/overlapping_panels.dart';
import '../../molecules/space_viewer.dart';
import '../../molecules/user_list.dart';
import '../../molecules/user_panel.dart';
import '../../organisms/side_navigation_bar.dart';

import 'package:flutter/material.dart' as m;

class MobileChatPage extends StatefulWidget {
  const MobileChatPage({super.key});

  @override
  State<MobileChatPage> createState() => _MobileChatPageState();
}

class _MobileChatPageState extends State<MobileChatPage> {
  late ClientManager _clientManager;
  late Space? selectedSpace;
  late Room? selectedRoom;
  late GlobalKey<OverlappingPanelsState> panelsKey;
  late GlobalKey<TimelineViewerState> timelineKey = GlobalKey<TimelineViewerState>();
  late Map<String, GlobalKey<TimelineViewerState>> timelines = {};
  late GlobalKey<MessageInputState> messageInput = GlobalKey();
  bool shouldMainIgnoreInput = false;
  bool homeSelected = false;

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    selectedRoom = null;
    selectedSpace = null;
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
                child: timelineView(),
              )
            : timelineView(),
        onDragStart: () {
          messageInput.currentState?.unfocus();
        },
        onSideChange: (side) {
          setState(() {
            shouldMainIgnoreInput = side != RevealSide.main;
          });
        },
        right: selectedRoom != null ? userList() : null);
  }

  Widget navigation(BuildContext newContext) {
    return Row(
      children: [
        SideNavigationBar(
          onHomeSelected: () {
            setState(() {
              homeSelected = true;
            });
          },
          onSpaceSelected: (index) {
            setState(() {
              homeSelected = false;
              selectedSpace = _clientManager.spaces[index];
            });
          },
        ),
        if (homeSelected) homePageView(),
        if (homeSelected == false && selectedSpace != null) spaceRoomSelector(newContext)
      ],
    );
  }

  Widget userList() {
    if (selectedRoom != null) {
      return Tile.low1(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 20, 0, 0),
            child: PeerList(
              selectedRoom!.members,
              key: selectedRoom!.key,
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
              directMessages: _clientManager.directMessages,
              onSelected: (index) {
                setState(() {
                  selectRoom(_clientManager.directMessages[index]);
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget timelineView() {
    if (selectedRoom != null) {
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
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: s(50), child: SpaceHeader(selectedSpace!)),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, s(50), 0),
                child: SpaceViewer(
                  selectedSpace!,
                  key: selectedSpace!.key,
                  onRoomInsert: selectedSpace!.onRoomAdded.stream,
                  onRoomSelected: (index) async {
                    selectRoom(selectedSpace!.rooms[index]);
                  },
                ),
              )),
              Tile.low2(
                child: SizedBox(
                  height: s(70),
                  child: UserPanel(
                    displayName: selectedSpace!.client.user!.displayName,
                    avatar: selectedSpace!.client.user!.avatar,
                    detail: selectedSpace!.client.user!.detail,
                    color: selectedSpace!.client.user!.color,
                  ),
                ),
              )
            ],
          ),
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
              SizedBox(height: s(50), child: RoomHeader(selectedRoom!)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: TimelineViewer(
                      key: timelines[selectedRoom!.identifier],
                      timeline: selectedRoom!.timeline!,
                    )),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, s(8)),
                      child: MessageInput(
                        key: messageInput,
                        onSendMessage: (message) {
                          selectedRoom!.sendMessage(message);
                          return MessageInputSendResult.clearText;
                        },
                      ),
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

  void selectRoom(Room room) async {
    // Putting this here so we can see a bit of the animation when the room button is clicked
    // feels better ^-^
    Future.delayed(const Duration(milliseconds: 125)).then((value) {
      panelsKey.currentState!.reveal(RevealSide.main);
      setState(() {
        shouldMainIgnoreInput = false;
      });
    });

    if (room == selectedRoom) return;

    if (!timelines.containsKey(room.identifier)) {
      timelines[room.identifier] = GlobalKey<TimelineViewerState>();
    }

    if (kDebugMode) {
      // Weird hacky work around mentioned in #2
      timelines[selectedRoom?.identifier]?.currentState!.prepareForDisposal();
      WidgetsBinding.instance.addPostFrameCallback((_) => _setSelectedRoom(room));
    } else {
      _setSelectedRoom(room);
    }
  }

  void _setSelectedRoom(Room room) async {
    setState(() {
      selectedRoom = room;
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          timelines[selectedRoom?.identifier]?.currentState!.forceToBottom();
        },
      );
    });
  }
}
