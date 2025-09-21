import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/organisms/invitation_view/incoming_invitations_view.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
import 'package:flutter/foundation.dart';
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

  @override
  void initState() {
    syncSub = widget.clientManager.onSync.stream.listen(onSync);
    updateRecent();
    super.initState();
  }

  @override
  void dispose() {
    syncSub?.cancel();
    super.dispose();
  }

  void onSync(void event) {
    setState(() {
      updateRecent();
    });
  }

  void updateRecent() {
    recentActivity = List.from(widget.clientManager.rooms);
    recentActivity.removeWhere((element) => element.lastEvent == null);

    mergeSort(recentActivity, compare: (a, b) {
      return b.lastEventTimestamp.compareTo(a.lastEventTimestamp);
    });

    if (recentActivity.length > widget.numRecentRooms) {
      recentActivity = recentActivity.sublist(0, widget.numRecentRooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        IncomingInvitationsWidget(widget.clientManager),
        HomeScreenView(
          clientManager: widget.clientManager,
          rooms: widget.clientManager.singleRooms,
          recentActivity: recentActivity,
          onRoomClicked: (room) =>
              EventBus.openRoom.add((room.identifier, room.client.identifier)),
          joinRoom: joinRoom,
          createRoom: createRoom,
        ),
      ],
    );
  }

  Future<void> joinRoom(Client client, String address) async {
    await client.joinRoom(address);
  }

  Future<void> createRoom(Client client, CreateRoomArgs args) async {
    await client.createRoom(args);
  }
}
