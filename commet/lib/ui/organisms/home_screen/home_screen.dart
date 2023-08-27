import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/navigation/navigation_signals.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
import 'package:flutter/material.dart';

import '../../../client/room.dart';

class HomeScreen extends StatefulWidget {
  final ClientManager clientManager;
  final int numRecentRooms;
  const HomeScreen(
      {super.key, required this.clientManager, this.numRecentRooms = 5});

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
    recentActivity = widget.clientManager.rooms
        .where((element) => element.lastEvent != null)
        .toList();

    recentActivity.sort((a, b) {
      return b.lastEvent!.originServerTs.compareTo(a.lastEvent!.originServerTs);
    });

    if (recentActivity.length > widget.numRecentRooms) {
      recentActivity = recentActivity.sublist(0, widget.numRecentRooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenView(
      rooms: widget.clientManager.singleRooms,
      recentActivity: recentActivity,
      onRoomClicked: (room) => NavigationSignals.openRoom.add(room.identifier),
      invitations: widget.clientManager.clients
          .map((e) => e.invitations)
          .fold(List.empty(growable: true), (previousValue, element) {
        previousValue!.addAll(element);
        return previousValue;
      }),
    );
  }
}
