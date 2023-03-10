import 'package:commet/client/client_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/side_panel_button.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/organisms/side_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../client/client.dart';
import '../../atoms/background.dart';
import '../../molecules/popup_dialog.dart';
import '../../molecules/space_selector.dart';
import '../../organisms/add_space_dialog.dart';
import '../settings/settings_page.dart';

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
  late Map<String, GlobalKey<TimelineViewerState>> timelines = Map();

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    selectedRoom = null;
    selectedSpace = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SideNavigationBar(
          onSpaceSelected: (index) {
            setState(() {
              selectedSpace = _clientManager.spaces[index];
            });
          },
        ),
        if (selectedSpace != null) spaceRoomSelector(),
        if (selectedRoom != null) roomChatView(),
      ],
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
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                          child: TimelineViewer(
                        key: timelines[selectedRoom!.identifier],
                        timeline: selectedRoom!.timeline!,
                      )),
                      MessageInput()
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
        child: Background.low1(
          context,
          child: Column(
            children: [
              Container(child: SizedBox(height: s(50), child: Container(child: SpaceHeader(selectedSpace!)))),
              Expanded(
                  child: SpaceViewer(
                selectedSpace!,
                key: selectedSpace!.key,
                onRoomInsert: selectedSpace!.onRoomAdded.stream,
                onRoomSelected: roomSelected,
              )),
              SizedBox(
                height: s(55),
                child: UserPanel(
                  selectedSpace!.client.user!,
                ),
              )
            ],
          ),
        ));
  }

  void roomSelected(index) {
    var room = selectedSpace!.rooms[index];
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
