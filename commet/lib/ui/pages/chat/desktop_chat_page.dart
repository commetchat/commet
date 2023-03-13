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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart';
import '../../../client/client.dart';

class DesktopChatPage extends StatefulWidget {
  const DesktopChatPage({super.key});

  @override
  State<DesktopChatPage> createState() => _DesktopChatPageState();
}

class _DesktopChatPageState extends State<DesktopChatPage> {
  late ClientManager _clientManager;
  late Space? selectedSpace;
  late Room? selectedRoom;
  late GlobalKey<TimelineViewerState> timelineKey = GlobalKey<TimelineViewerState>();
  late Map<String, GlobalKey<TimelineViewerState>> timelines = {};

  late bool homePageSelected = false;

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    selectedRoom = null;
    selectedSpace = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            SideNavigationBar(
              onSpaceSelected: (index) {
                setState(() {
                  homePageSelected = false;
                  selectedSpace = _clientManager.spaces[index];
                });
              },
              onHomeSelected: () {
                setState(() {
                  homePageSelected = true;
                });
              },
            ),
            if (homePageSelected) homePageView(),
            if (!homePageSelected && selectedSpace != null) spaceRoomSelector(),
            if (selectedRoom != null) roomChatView(),
          ],
        ),
        if (selectedRoom != null)
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
          directMessages: _clientManager.directMessages,
          onSelected: (index) {
            setState(() {
              selectRoom(_clientManager.directMessages[index]);
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
        SizedBox(height: s(50), child: RoomHeader(selectedRoom!)),
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
                        key: timelines[selectedRoom!.identifier],
                        timeline: selectedRoom!.timeline!,
                      )),
                      MessageInput(
                        onSendMessage: (message) {
                          selectedRoom!.sendMessage(message);
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
                    selectedRoom!.members,
                    key: selectedRoom!.key,
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
              SizedBox(height: s(50), child: SpaceHeader(selectedSpace!)),
              Expanded(
                  child: SpaceViewer(
                selectedSpace!,
                key: selectedSpace!.key,
                onRoomInsert: selectedSpace!.onRoomAdded.stream,
                onRoomSelected: (index) {
                  selectRoom(selectedSpace!.rooms[index]);
                },
              )),
              Tile.low2(
                child: SizedBox(
                  height: s(65),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: UserPanel(
                      displayName: selectedSpace!.client.user!.displayName,
                      avatar: selectedSpace!.client.user!.avatar,
                      detail: selectedSpace!.client.user!.detail,
                      color: selectedSpace!.client.user!.color,
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  void selectRoom(Room room) {
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

  void _setSelectedRoom(Room room) {
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
