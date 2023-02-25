import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../client/client.dart';
import '../molecules/space_selector.dart';

class DesktopChatPage extends StatefulWidget {
  const DesktopChatPage({super.key});

  @override
  State<DesktopChatPage> createState() => _DesktopChatPageState();
}

class _DesktopChatPageState extends State<DesktopChatPage> {
  late ClientManager _clientManager;
  late Space? selectedSpace;
  late Room? selectedRoom;

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
        SizedBox(
            width: 70,
            child: SpaceSelector(
              _clientManager.spaces,
              onSpaceInsert: _clientManager.onSpaceAdded.stream,
              showSpaceOwnerAvatar: true,
              onSelected: (index) {
                setState(() {
                  selectedSpace = _clientManager.spaces[index];
                });

                print("Selected Space: " + selectedSpace!.displayName);
              },
            )),
        if (selectedSpace != null)
          SizedBox(
              width: 250,
              child: Column(
                children: [
                  Container(child: SizedBox(height: 50, child: Container(child: SpaceHeader(selectedSpace!)))),
                  Expanded(
                      child: SpaceViewer(
                    selectedSpace!,
                    key: selectedSpace!.key,
                    onRoomInsert: selectedSpace!.onRoomAdded.stream,
                    onRoomSelected: (index) {
                      setState(() {
                        selectedRoom = selectedSpace!.rooms[index];
                      });
                    },
                  )),
                  SizedBox(
                    height: 55,
                    child: Container(color: Colors.red, child: UserPanel(selectedSpace!.client.user!)),
                  )
                ],
              )),
        if (selectedRoom != null)
          Flexible(
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
                              key: selectedRoom!.key,
                              room: selectedRoom!,
                            )),
                            MessageInput()
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 250, child: Placeholder()),
                  ],
                ),
              ),
            ],
          )),
      ],
    );
  }
}
