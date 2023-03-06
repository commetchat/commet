import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/side_panel_button.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/user_list.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../client/client.dart';
import '../atoms/popup_dialog.dart';
import '../molecules/space_selector.dart';
import '../organisms/add_space_dialog.dart';

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
        spaceSelector(),
        if (selectedSpace != null) spaceRoomSelector(),
        if (selectedRoom != null) roomChatView(),
      ],
    );
  }

  SizedBox spaceSelector() {
    return SizedBox(
        width: 70,
        child: SpaceSelector(
          _clientManager.spaces,
          onSpaceInsert: _clientManager.onSpaceAdded.stream,
          header: SidePanelButton(
            tooltip: "Home",
          ),
          footer: SidePanelButton(
            tooltip: "Add a Space",
            onTap: () {
              PopupDialog.Show(context, AddSpaceDialog(), title: "Add Space");
            },
          ),
          showSpaceOwnerAvatar: true,
          onSelected: (index) {
            setState(() {
              selectedSpace = _clientManager.spaces[index];
            });
            print("Selected Space: " + selectedSpace!.displayName);
          },
        ));
  }

  Flexible roomChatView() {
    return Flexible(
        child: Column(
      children: [
        SizedBox(height: 50, child: RoomHeader(selectedRoom!)),
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
                  width: 250,
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
        width: 250,
        child: Column(
          children: [
            Container(child: SizedBox(height: 50, child: Container(child: SpaceHeader(selectedSpace!)))),
            Expanded(
                child: SpaceViewer(
              selectedSpace!,
              key: selectedSpace!.key,
              onRoomInsert: selectedSpace!.onRoomAdded.stream,
              onRoomSelected: roomSelected,
            )),
            SizedBox(
              height: 55,
              child: Container(color: Colors.red, child: UserPanel(selectedSpace!.client.user!)),
            )
          ],
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
