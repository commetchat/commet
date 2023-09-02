import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';

import '../atoms/dot_indicator.dart';

class DirectMessageList extends StatefulWidget {
  const DirectMessageList(
      {required this.clientManager, this.onSelected, super.key});
  final ClientManager clientManager;
  @override
  State<DirectMessageList> createState() => _DirectMessageListState();
  final Function(Room room)? onSelected;
}

class _DirectMessageListState extends State<DirectMessageList> {
  int numDMs = 0;
  Room? selectedRoom;
  late StreamSubscription? onDmUpdatedSubscription;
  late List<Room> rooms;

  @override
  void initState() {
    onDmUpdatedSubscription = widget
        .clientManager.onDirectMessageRoomUpdated.stream
        .listen(onRoomUpdated);

    widget.clientManager.onDirectMessageRoomAdded.stream.listen(onRoomAdded);

    updateRoomsList();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onRoomAdded(int index) {
    setState(() {
      updateRoomsList();
    });
  }

  void onRoomUpdated(Room room) {
    if (mounted)
      setState(() {
        sortRooms();
      });
  }

  void sortRooms() {
    rooms.sort((a, b) {
      return b.lastEventTimestamp.compareTo(a.lastEventTimestamp);
    });
  }

  void updateRoomsList() {
    rooms = List.from(widget.clientManager.directMessages);
    sortRooms();
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList(
      itemData: rooms,
      initialAnimation: false,
      itemBuilder: (context, room) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 1, 0, 1),
          child: SizedBox(
            height: 55,
            child: TextButton(
              room.displayName,
              avatar: room.avatar,
              avatarRadius: 18,
              avatarPlaceholderColor: room.defaultColor,
              avatarPlaceholderText: room.displayName,
              footer: room.displayNotificationCount > 0
                  ? const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: DotIndicator(),
                    )
                  : null,
              onTap: () {
                setState(() {
                  selectedRoom = room;
                  widget.onSelected?.call(room);
                });
              },
            ),
          ),
        );
      },
    );
  }
}
