import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/invitation_view/incoming_invitations_view.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class HomeScreen extends StatefulWidget {
  final ClientManager clientManager;
  final Client? filterClient;
  final int numRecentRooms;
  final void Function()? onBurgerMenuTap;
  const HomeScreen({
    super.key,
    required this.clientManager,
    this.filterClient,
    this.onBurgerMenuTap,
    this.numRecentRooms = 5,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Room> recentActivity;

  Client? filterClient;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    filterClient = widget.filterClient;

    subscriptions = [
      widget.clientManager.onSync.stream.listen(onSync),
      widget.clientManager.onClientRemoved.stream.listen((_) {
        setState(() {
          updateRecent();
        });
      }),
      EventBus.setFilterClient.stream.listen(setFilterClient),
    ];

    if (preferences.checkForUpdates == true) {
      UpdateChecker.checkForUpdates();
    }

    updateRecent();
    super.initState();
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }

    super.dispose();
  }

  void onSync(void event) {
    setState(() {
      updateRecent();
    });
  }

  void updateRecent() {
    recentActivity =
        List.from(filterClient?.rooms ?? widget.clientManager.rooms);

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
    return Column(
      children: [
        if (Layout.mobile)
          tiamat.Tile.low(
            caulkClipBottomRight: true,
            caulkClipBottomLeft: true,
            caulkBorderBottom: true,
            child: ScaledSafeArea(
              bottom: false,
              left: false,
              right: false,
              child: SizedBox(
                height: 50,
                child: HeaderView(
                  showBurger: Layout.mobile,
                  onBurgerMenuTap: widget.onBurgerMenuTap,
                  text: CommonStrings.promptHome,
                ),
              ),
            ),
          ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    IncomingInvitationsWidget(widget.clientManager),
                    HomeScreenView(
                      clientManager: widget.clientManager,
                      rooms: widget.clientManager
                          .singleRooms(filterClient: filterClient),
                      recentActivity: recentActivity,
                      onRoomClicked: (room) => EventBus.openRoom
                          .add((room.roomId, room.client.identifier)),
                      joinRoom: joinRoom,
                      createRoom: createRoom,
                    ),
                  ],
                ),
              )
            ],
          ),
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

  void setFilterClient(Client? event) {
    setState(() {
      filterClient = event;
      updateRecent();
    });
  }
}
