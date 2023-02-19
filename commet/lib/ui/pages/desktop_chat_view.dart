import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../client/client.dart';
import '../molecules/space_selector.dart';

class DesktopChatView extends StatefulWidget {
  const DesktopChatView({super.key});

  @override
  State<DesktopChatView> createState() => _DesktopChatViewState();
}

class _DesktopChatViewState extends State<DesktopChatView> {
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
              onSelected: (index) {
                setState(() {
                  selectedSpace = _clientManager.spaces.getItems()[index];
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
                    onRoomSelected: (index) {
                      setState(() {
                        selectedRoom = selectedSpace!.rooms.getItems()[index];
                      });
                    },
                  )),
                  SizedBox(
                    height: 70,
                    child: Placeholder(),
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
                      child: Column(
                        children: [
                          Expanded(
                              child: TimelineViewer(
                            key: selectedRoom!.key,
                            room: selectedRoom!,
                          )),
                          SizedBox(
                            height: 80,
                            child: MessageInput(),
                          )
                        ],
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
