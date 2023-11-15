import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:flutter/material.dart' as material;

class BubblePage extends StatefulWidget {
  const BubblePage(this.clientManager,
      {super.key, this.initialClientId, this.initialRoom});
  final ClientManager clientManager;
  final String? initialRoom;
  final String? initialClientId;

  @override
  State<BubblePage> createState() => BubblePageState();
}

class BubblePageState extends State<BubblePage> {
  Room? _currentRoom;

  StreamSubscription? onSpaceUpdateSubscription;
  StreamSubscription? onRoomUpdateSubscription;

  ClientManager get clientManager => widget.clientManager;

  Room? get currentRoom => _currentRoom;

  @override
  void initState() {
    super.initState();

    if (widget.initialClientId != null && widget.initialRoom != null) {
      _currentRoom = clientManager
          .getClient(widget.initialClientId!)
          ?.getRoom(widget.initialRoom!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return currentRoom == null
        ? const Placeholder()
        : Tile(
            child: material.Scaffold(
              backgroundColor: material.Theme.of(context).colorScheme.surface,
              body: SafeArea(
                child: Placeholder(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: RoomHeader(
                          currentRoom!,
                        ),
                      ),
                      Flexible(
                        child: Chat(
                          currentRoom!,
                          key: ValueKey(
                              "room-timeline-key-${currentRoom!.localId}"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
