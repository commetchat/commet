import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class RoomQuickAccessMenu {
  final Room room;
  late final List<RoomQuickAccessMenuEntry> actions;

  RoomQuickAccessMenu({required this.room}) {
    final bool canSearch =
        room.client.getComponent<EventSearchComponent>() != null;

    actions = [
      if (canSearch)
        RoomQuickAccessMenuEntry(
            name: "Search",
            action: (context) => EventBus.startSearch.add(null),
            icon: Icons.search),
    ];
  }
}

class RoomQuickAccessMenuEntry {
  final String name;
  final Function(BuildContext context)? action;
  final IconData icon;

  RoomQuickAccessMenuEntry(
      {required this.name, required this.action, required this.icon});
}
