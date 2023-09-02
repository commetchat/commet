import 'package:commet/client/invitation.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/molecules/invitation_display.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';

import '../../../client/room.dart';

class HomeScreenView extends StatelessWidget {
  final List<Room>? rooms;
  final List<Room>? recentActivity;
  final List<Invitation>? invitations;
  final Function(Room room)? onRoomClicked;
  final Future<void> Function(Invitation invite)? acceptInvite;
  final Future<void> Function(Invitation invite)? rejectInvite;

  const HomeScreenView(
      {super.key,
      this.rooms,
      this.recentActivity,
      this.onRoomClicked,
      this.acceptInvite,
      this.rejectInvite,
      this.invitations});

  String get labelHomeRecentActivity => Intl.message("Recent Activity",
      name: "labelHomeRecentActivity",
      desc: "Short label for header of recent room activity");

  String get labelHomeRoomsList => Intl.message("Rooms",
      name: "labelHomeRoomsList", desc: "Short label for header of rooms list");

  String get labelHomeInvitations => Intl.message("Invitations",
      name: "labelHomeInvitations",
      desc: "Short label for header of invitations list");

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (invitations?.isNotEmpty == true) invitationsList(),
        recentRooms(),
        roomsList()
      ]
          .map((e) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: e,
              ))
          .toList(),
    );
  }

  Widget recentRooms() {
    return Panel(
        mode: TileType.surface,
        header: labelHomeRecentActivity,
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
        mode: TileType.surface,
        header: labelHomeRoomsList,
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

  Widget invitationsList() {
    return Panel(
        mode: TileType.surfaceLow1,
        header: labelHomeInvitations,
        child: ImplicitlyAnimatedList(
          physics: const NeverScrollableScrollPhysics(),
          initialAnimation: false,
          shrinkWrap: true,
          itemData: invitations!,
          itemBuilder: (context, invitation) {
            return InvitationDisplay(
              invitation,
              acceptInvitation: acceptInvite,
              rejectInvitation: rejectInvite,
            );
          },
        ));
  }
}
