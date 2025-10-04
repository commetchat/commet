import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import '../atoms/dot_indicator.dart';

class DirectMessageList extends StatefulWidget {
  const DirectMessageList(
      {required this.directMessages, this.onSelected, super.key});
  final DirectMessagesInterface directMessages;
  @override
  State<DirectMessageList> createState() => _DirectMessageListState();
  final Function(Room room)? onSelected;
}

class _DirectMessageListState extends State<DirectMessageList> {
  int numDMs = 0;
  Room? selectedRoom;
  late List<StreamSubscription> subscriptions;
  late List<Room> rooms;

  @override
  void initState() {
    subscriptions = [
      widget.directMessages.onRoomsListUpdated.listen(onListUpdated)
    ];

    updateRoomsList();

    super.initState();
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }
    super.dispose();
  }

  void onListUpdated(void event) {
    setState(() {
      updateRoomsList();
    });
  }

  void sortRooms() {
    mergeSort(rooms, compare: (a, b) {
      return b.lastEventTimestamp.compareTo(a.lastEventTimestamp);
    });
  }

  void updateRoomsList() {
    rooms = List.from(widget.directMessages.directMessageRooms);
    sortRooms();
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList(
      itemData: rooms,
      initialAnimation: false,
      itemBuilder: (context, room) {
        final component = room.client.getComponent<DirectMessagesComponent>();
        final id = component?.getDirectMessagePartnerId(room);
        if (id == null) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 1, 0, 1),
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                Expanded(
                  child: UserPanel(
                    userId: id,
                    key: ValueKey("home-screen-direct-message-entry-${id}"),
                    client: room.client,
                    contextRoom: room,
                    isDirectMessage: true,
                    onTap: () => setState(() {
                      selectedRoom = room;
                      widget.onSelected?.call(room);
                    }),
                  ),
                ),
                room.displayNotificationCount > 0
                    ? const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: DotIndicator(),
                      )
                    : Container()
              ],
            ),
          ),
        );
      },
    );
  }
}
