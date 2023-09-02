import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';

import '../atoms/dot_indicator.dart';

class DirectMessageList extends StatefulWidget {
  const DirectMessageList(
      {required this.directMessages, this.onSelected, super.key});
  final List<Room> directMessages;
  @override
  State<DirectMessageList> createState() => _DirectMessageListState();
  final Function(Room room)? onSelected;
}

class _DirectMessageListState extends State<DirectMessageList> {
  int numDMs = 0;
  Room? selectedRoom;
  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    subscriptions = widget.directMessages
        .map(
            (e) => e.onUpdate.stream.listen((event) => onRoomUpdated(e, event)))
        .toList();

    numDMs = widget.directMessages.length;
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList(
      itemData: widget.directMessages,
      initialAnimation: false,
      itemBuilder: (context, room) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
          child: SizedBox(
            height: 35,
            child: TextButton(
              room.displayName,
              avatar: room.avatar,
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

  void onRoomUpdated(Room room, void event) {
    setState(() {});
  }
}
