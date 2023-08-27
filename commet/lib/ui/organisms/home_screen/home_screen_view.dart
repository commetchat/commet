import 'package:commet/ui/atoms/room_panel.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';

import '../../../client/room.dart';

class HomeScreenView extends StatelessWidget {
  final List<Room>? rooms;
  final List<Room>? recentActivity;
  final Function(Room room)? onRoomClicked;
  const HomeScreenView(
      {super.key, this.rooms, this.recentActivity, this.onRoomClicked});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [recentRooms(), roomsList()]
          .map((e) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: e,
              ))
          .toList(),
    );
  }

  Widget recentRooms() {
    return Panel(
        mode: TileType.surfaceLow1,
        header: "Recent Activity",
        child: ImplicitlyAnimatedList(
          shrinkWrap: true,
          itemData: recentActivity!,
          initialAnimation: false,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, room) {
            return RoomPanel(
              displayName: room.displayName,
              avatar: room.avatar,
              color: room.defaultColor,
              recentEventBody: room.lastEvent!.body,
              recentEventSender:
                  room.client.fetchPeer(room.lastEvent!.senderId).displayName,
              recentEventSenderColor:
                  room.getColorOfUser(room.lastEvent!.senderId),
              onTap: () => onRoomClicked?.call(room),
            );
          },
        ));
  }

  Widget roomsList() {
    return Panel(
        mode: TileType.surfaceLow1,
        header: "Rooms",
        child: ImplicitlyAnimatedList(
          physics: const NeverScrollableScrollPhysics(),
          initialAnimation: false,
          shrinkWrap: true,
          itemData: rooms!,
          itemBuilder: (context, room) {
            return RoomPanel(
              displayName: room.displayName,
              avatar: room.avatar,
              color: room.defaultColor,
              recentEventBody: room.lastEvent?.body,
              recentEventSender: room.lastEvent != null
                  ? room.client.fetchPeer(room.lastEvent!.senderId).displayName
                  : null,
              recentEventSenderColor: room.lastEvent != null
                  ? room.getColorOfUser(room.lastEvent!.senderId)
                  : null,
              onTap: () => onRoomClicked?.call(room),
            );
          },
        ));
  }
}
