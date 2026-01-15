import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/invitation/invitation.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/molecules/alert_view.dart';
import 'package:commet/ui/molecules/invitation_display.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class HomeScreenView extends StatelessWidget {
  final ClientManager clientManager;
  final List<Room>? rooms;
  final List<Room>? recentActivity;
  final List<Invitation>? invitations;
  final Function(Room room)? onRoomClicked;
  final Future<void> Function(Invitation invite)? acceptInvite;
  final Future<void> Function(Invitation invite)? rejectInvite;
  final Future<void> Function(Client client, String address)? joinRoom;
  final Future<void> Function(Client client, CreateRoomArgs args)? createRoom;

  const HomeScreenView(
      {super.key,
      required this.clientManager,
      this.rooms,
      this.recentActivity,
      this.onRoomClicked,
      this.acceptInvite,
      this.rejectInvite,
      this.joinRoom,
      this.createRoom,
      this.invitations});

  String get labelHomeRecentActivity => Intl.message("Recent Activity",
      name: "labelHomeRecentActivity",
      desc: "Short label for header of recent room activity");

  String get labelHomeAlerts => Intl.message("Alerts",
      name: "labelHomeAlerts", desc: "Short label for header of alerts");

  String get labelHomeRoomsList => Intl.message("Rooms",
      name: "labelHomeRoomsList", desc: "Short label for header of rooms list");

  String get labelHomeInvitations => Intl.message("Invitations",
      name: "labelHomeInvitations",
      desc: "Short label for header of invitations list");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (clientManager.alertManager.alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: alerts(),
          ),
        if (invitations?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: invitationsList(),
          ),
        if (recentActivity?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: recentRooms(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: roomsList(context),
        )
      ],
    );
  }

  Widget alerts() {
    return Panel(
        mode: TileType.surfaceContainerLow,
        header: labelHomeAlerts,
        child: ImplicitlyAnimatedList(
          shrinkWrap: true,
          itemData: clientManager.alertManager.alerts,
          initialAnimation: false,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, alert) {
            return AlertView(alert);
          },
        ));
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
              body: room.lastEvent?.plainTextBody,
              recentEventSender: room.lastEvent != null
                  ? room
                      .getMemberOrFallback(room.lastEvent!.senderId)
                      .displayName
                  : null,
              recentEventSenderColor: room.lastEvent != null
                  ? room.getColorOfUser(room.lastEvent!.senderId)
                  : null,
              onTap: () => onRoomClicked?.call(room),
              showUserAvatar: clientManager.rooms
                      .where((element) => element.identifier == room.identifier)
                      .length >
                  1,
              userAvatar: room.client.self!.avatar,
              userDisplayName: room.client.self!.displayName,
              userColor: room.client.self!.defaultColor,
            );
          },
        ));
  }

  Widget roomsList(BuildContext context) {
    return Panel(
        mode: TileType.surface,
        header: labelHomeRoomsList,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ImplicitlyAnimatedList(
              physics: const NeverScrollableScrollPhysics(),
              initialAnimation: false,
              shrinkWrap: true,
              itemData: rooms!,
              itemBuilder: (context, room) {
                return RoomPanel(
                  displayName: room.displayName,
                  avatar: room.avatar,
                  color: room.defaultColor,
                  body: room.lastEvent?.plainTextBody,
                  recentEventSender: room.lastEvent != null
                      ? room
                          .getMemberOrFallback(room.lastEvent!.senderId)
                          .displayName
                      : null,
                  recentEventSenderColor: room.lastEvent != null
                      ? room.getColorOfUser(room.lastEvent!.senderId)
                      : null,
                  onTap: () => onRoomClicked?.call(room),
                  showUserAvatar: clientManager.rooms
                          .where((element) =>
                              element.identifier == room.identifier)
                          .length >
                      1,
                  userAvatar: room.client.self!.avatar,
                  userDisplayName: room.client.self!.displayName,
                  userColor: room.client.self!.defaultColor,
                );
              },
            ),
            tiamat.CircleButton(
              radius: BuildConfig.MOBILE ? 24 : 16,
              icon: Icons.add,
              onPressed: () => addRoomDialog(context),
            ),
          ],
        ));
  }

  Widget invitationsList() {
    return Panel(
        mode: TileType.surfaceContainer,
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

  void addRoomDialog(BuildContext context) {
    GetOrCreateRoom.show(null, context,
        pickExisting: false, showAllRoomTypes: true);
  }
}
