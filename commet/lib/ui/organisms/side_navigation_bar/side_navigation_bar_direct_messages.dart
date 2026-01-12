import 'dart:async';

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

class SideNavigationBarDirectMessages extends StatefulWidget {
  const SideNavigationBarDirectMessages(this.directMessages,
      {super.key, this.onRoomTapped});
  final DirectMessagesInterface directMessages;

  final void Function(Room room)? onRoomTapped;

  @override
  State<SideNavigationBarDirectMessages> createState() =>
      _SideNavigationBarDirectMessagesState();
}

class _SideNavigationBarDirectMessagesState
    extends State<SideNavigationBarDirectMessages> {
  StreamSubscription? sub;

  late List<Room> rooms;

  @override
  void initState() {
    super.initState();
    rooms = widget.directMessages.highlightedRoomsList;
    sub = widget.directMessages.onHighlightedRoomsListUpdated
        .listen(onListUpdated);
  }

  void onListUpdated(void event) {
    setState(() {
      rooms = widget.directMessages.highlightedRoomsList;
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
            spaceId: data.identifier,
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
