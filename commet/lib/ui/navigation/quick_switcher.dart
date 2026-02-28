import 'package:collection/collection.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class QuickSwitcher extends StatefulWidget {
  const QuickSwitcher({super.key});

  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (!isShowing) {
      isShowing = true;

      await showGeneralDialog(
        barrierLabel: "QUICK_SWITCHER",
        context: context,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        pageBuilder: (context, _, __) {
          return Center(
            child: Theme(
              data: Theme.of(context),
              child: AlertDialog(title: null, content: QuickSwitcher()),
            ),
          );
        },
      );

      isShowing = false;
    }
  }

  @override
  State<QuickSwitcher> createState() => _QuickSwitcherState();
}

abstract class QuickSwitcherSearchItem {
  String get searchEntry;

  String get id;

  void onTap(BuildContext context);

  Widget build(BuildContext context);
}

class QuickSwitcherSearchItemRoom implements QuickSwitcherSearchItem {
  Room room;

  @override
  String id;

  QuickSwitcherSearchItemRoom(this.room, {required this.id});

  @override
  String get searchEntry => room.displayName;

  @override
  Widget build(BuildContext context) {
    var sender = room.lastEvent != null
        ? room.getMemberOrFallback(room.lastEvent!.senderId)
        : null;

    return RoomPanel(
      displayName: room.displayName,
      color: room.defaultColor,
      onTap: () => onTap(context),
      avatar: room.avatar,
      recentEventSender: sender?.displayName,
      recentEventSenderColor: sender?.defaultColor,
      body: room.lastEvent?.plainTextBody,
    );
  }

  @override
  void onTap(BuildContext context) {
    EventBus.openRoom.add((room.identifier, room.client.identifier));

    Navigator.of(context).pop();
  }
}

class _QuickSwitcherState extends State<QuickSwitcher> {
  List<QuickSwitcherSearchItem> items = List.empty(growable: true);

  List<QuickSwitcherSearchItem> searchResults = List.empty();

  @override
  void initState() {
    for (var client in clientManager!.clients) {
      var dm = client.getComponent<DirectMessagesComponent>();

      for (var room in client.rooms) {
        if (dm?.isRoomDirectMessage(room) == true) {
          var partner = dm!.getDirectMessagePartnerId(room);
          items.add(QuickSwitcherSearchItemRoom(room,
              id: partner ?? room.identifier));
        } else {
          items.add(QuickSwitcherSearchItemRoom(room, id: room.identifier));
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(icon: Icon(Icons.search)),
            maxLines: 1,
            onChanged: doSearch,
            onSubmitted: (value) {
              searchResults.firstOrNull?.onTap(context);
            },
            autofocus: true,
          ),
          if (searchResults.isEmpty) buildDefaultView(),
          if (searchResults.isNotEmpty)
            tiamat.Panel(
              header: "Search Results",
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: Column(
                  children: [
                    for (var result in searchResults) result.build(context),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Column buildDefaultView() {
    return Column(
      children: [
        tiamat.Panel(
          header: "Direct Messages",
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (var room in clientManager!
                    .directMessages.directMessageRooms
                    .sorted((a, b) =>
                        b.lastEventTimestamp.compareTo(a.lastEventTimestamp)))
                  Material(
                    child: InkWell(
                      onTap: () {
                        EventBus.openRoom
                            .add((room.identifier, room.client.identifier));

                        Navigator.of(context).pop();
                      },
                      child: tiamat.Avatar(
                          image: room.avatar,
                          placeholderColor: room.defaultColor,
                          placeholderText: room.displayName),
                    ),
                  )
              ],
            ),
          ),
        ),
        tiamat.Panel(
            header: "Recent Activity",
            child: Column(
              spacing: 0,
              children: [
                for (var room in clientManager!.rooms
                    .sorted((a, b) =>
                        b.lastEventTimestamp.compareTo(a.lastEventTimestamp))
                    .sublist(0, 4))
                  RoomPanel(
                    onTap: () {
                      EventBus.openRoom
                          .add((room.identifier, room.client.identifier));

                      Navigator.of(context).pop();
                    },
                    displayName: room.displayName,
                    color: room.defaultColor,
                    avatar: room.avatar,
                    recentEventSender: room.lastEvent != null
                        ? room
                            .getMemberOrFallback(room.lastEvent!.senderId)
                            .displayName
                        : null,
                    recentEventSenderColor: room.lastEvent != null
                        ? room
                            .getMemberOrFallback(room.lastEvent!.senderId)
                            .defaultColor
                        : null,
                    body: room.lastEvent?.plainTextBody,
                  )
              ],
            ))
      ],
    );
  }

  void doSearch(String text) {
    if (text.isEmpty) {
      setState(() {
        searchResults = List.empty();
      });
      return;
    }

    var searchItems = items;
    var searchText = text;

    if (text.startsWith("@")) {
      searchItems = items.where((i) => i.id.startsWith("@")).toList();
    }

    var fuzzy = Fuzzy<QuickSwitcherSearchItem>(searchItems,
        options: FuzzyOptions(keys: [
          WeightedKey(
              name: "searchEntry",
              getter: (result) {
                return result.searchEntry;
              },
              weight: 1),
          WeightedKey(
              name: "id",
              getter: (result) {
                return result.id;
              },
              weight: 1)
        ]));

    var results = fuzzy.search(searchText, 5).map((e) => e.item).toList();
    setState(() {
      searchResults = results;
    });
  }
}
