import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/invitation.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final ClientManager clientManager;
  final int numRecentRooms;
  const HomeScreen({
    super.key,
    required this.clientManager,
    this.numRecentRooms = 5,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Room> recentActivity;
  StreamSubscription? syncSub;
  late List<Invitation> invitations;

  @override
  void initState() {
    syncSub = widget.clientManager.onSync.stream.listen(onSync);
    updateRecent();
    refreshInvitations();
    super.initState();
  }

  @override
  void dispose() {
    syncSub?.cancel();
    super.dispose();
  }

  void refreshInvitations() {
    invitations = widget.clientManager.clients
        .map((e) => e.invitations)
        .fold(List.empty(growable: true), (previousValue, element) {
      previousValue.addAll(element);
      return previousValue;
    });
  }

  void onSync(void event) {
    setState(() {
      updateRecent();
      refreshInvitations();
    });
  }

  void updateRecent() {
    recentActivity = widget.clientManager.rooms;

    recentActivity.sort((a, b) {
      return b.lastEventTimestamp.compareTo(a.lastEventTimestamp);
    });

    if (recentActivity.length > widget.numRecentRooms) {
      recentActivity = recentActivity.sublist(0, widget.numRecentRooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenView(
      clientManager: widget.clientManager,
      rooms: widget.clientManager.singleRooms,
      recentActivity: recentActivity,
      onRoomClicked: (room) =>
          EventBus.openRoom.add((room.identifier, room.client.identifier)),
      acceptInvite: acceptInvitation,
      rejectInvite: rejectInvitation,
      joinRoom: joinRoom,
      createRoom: createRoom,
      invitations: invitations,
    );
  }

  Future<void> acceptInvitation(Invitation invite) async {
    for (var client in widget.clientManager.clients) {
      if (client.invitations.contains(invite)) {
        await client.acceptInvitation(invite);
        break;
      }
    }

    setState(() {
      refreshInvitations();
    });
  }

  Future<void> rejectInvitation(Invitation invite) async {
    for (var client in widget.clientManager.clients) {
      if (client.invitations.contains(invite)) {
        await client.rejectInvitation(invite);
        break;
      }
    }

    setState(() {
      refreshInvitations();
    });
  }

  Future<void> joinRoom(Client client, String address) async {
    await client.joinRoom(address);
  }

  Future<void> createRoom(Client client, String name, RoomVisibility visibility,
      bool enableE2EE) async {
    await client.createRoom(name, visibility, enableE2EE: enableE2EE);
  }
}
