import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

class SideNavigationBarDirectMessages extends StatefulWidget {
  const SideNavigationBarDirectMessages(this.directMessages,
      {super.key, this.onRoomTapped, this.filterClient});
  final DirectMessagesInterface directMessages;
  final Client? filterClient;

  final void Function(Room room)? onRoomTapped;

  @override
  State<SideNavigationBarDirectMessages> createState() =>
      _SideNavigationBarDirectMessagesState();
}

class _SideNavigationBarDirectMessagesState
    extends State<SideNavigationBarDirectMessages> {
  late List<Room> rooms;
  Client? filterClient;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();
    filterClient = widget.filterClient;

    rooms = widget.directMessages.highlightedRoomsList;
    subscriptions = [
      EventBus.setFilterClient.stream.listen(setFilterClient),
      widget.directMessages.onHighlightedRoomsListUpdated.listen(onListUpdated),
    ];
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }

    super.dispose();
  }

  void setFilterClient(Client? event) {
    setState(() {
      filterClient = event;
    });

    onListUpdated(null);
  }

  void onListUpdated(void event) {
    setState(() {
      rooms = widget.directMessages.highlightedRoomsList;

      if (filterClient != null) {
        rooms = rooms.where((i) => i.client == filterClient).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool empty = rooms.isEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, empty ? 0 : 4, 0, 0),
      child: ImplicitlyAnimatedList(
        shrinkWrap: true,
        itemData: rooms,
        padding: const EdgeInsets.all(0),
        itemBuilder: (context, data) {
          // return tiamat.Text.labelLow(data.displayName);
          return SpaceIcon(
            displayName: data.displayName,
            placeholderColor: data.defaultColor,
            spaceId: data.roomId,
            avatar: data.avatar,
            width: 70,
            highlightedNotificationCount: data.notificationCount,
            onTap: () => widget.onRoomTapped?.call(data),
          );
        },
      ),
    );
  }
}
