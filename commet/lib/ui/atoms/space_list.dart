import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/space_child.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/room_text_button.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceList extends StatefulWidget {
  const SpaceList(this.space,
      {this.onRoomSelected, this.isTopLevel = true, super.key});
  final Function(Room room, {bool bypassSpecialRoomType})? onRoomSelected;

  final bool isTopLevel;

  final Space space;

  @override
  State<SpaceList> createState() => _SpaceListState();
}

class _SpaceListState extends State<SpaceList> {
  late List<SpaceChild> children;

  late List<StreamSubscription> subs;

  Room? selectedRoom;
  String get labelRoomsList => Intl.message("Rooms",
      desc: "Header label for the list of rooms", name: "labelRoomsList");

  @override
  void initState() {
    children = widget.space.children;

    subs = [
      EventBus.onSelectedRoomChanged.stream.listen(onRoomSelected),
      widget.space.onUpdate.listen(onSpaceUpdated),
      widget.space.onChildSpaceAdded.listen(onSpaceUpdated),
      widget.space.onChildSpaceRemoved.listen(onSpaceUpdated),
      widget.space.onRoomAdded.listen(onRoomUpdated),
      widget.space.onRoomRemoved.listen(onRoomUpdated),
      for (var room in widget.space.rooms) room.onUpdate.listen(onRoomUpdated),
      preferences.onSettingChanged.listen((_) => setState(() {})),
    ];

    super.initState();
  }

  void onSpaceUpdated(void event) {
    setState(() {
      children = widget.space.children;
    });
  }

  void onRoomUpdated(void event) {
    setState(() {
      children = widget.space.children;
    });
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void onRoomSelected(Room? event) {
    if (mounted)
      setState(() {
        selectedRoom = event;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var child in children) buildChild(child),
      ],
    );
  }

  Widget roomsList() {
    if (widget.isTopLevel) {
      return tiamat.TextButtonExpander(labelRoomsList,
          childrenPadding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
          initiallyExpanded: true,
          iconColor: Theme.of(context).colorScheme.secondary,
          textColor: Theme.of(context).colorScheme.secondary,
          children: [buildRoomsList()]);
    } else {
      return buildRoomsList();
    }
  }

  Widget buildRoomsList() {
    return ImplicitlyAnimatedList(
      itemData: widget.space.rooms,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      initialAnimation: false,
      itemBuilder: (context, data) {
        return RoomTextButton(
          data,
          onTap: widget.onRoomSelected,
          highlight: selectedRoom == data,
        );
      },
    );
  }

  Widget buildChild(SpaceChild child) {
    if (child case SpaceChildSpace _)
      return tiamat.TextButtonExpander(child.child.displayName,
          initiallyExpanded: true,
          childrenPadding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
          iconColor: Theme.of(context).colorScheme.secondary,
          textColor: Theme.of(context).colorScheme.secondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: SpaceList(
                child.child,
                isTopLevel: false,
                onRoomSelected: widget.onRoomSelected,
              ),
            )
          ]);

    if (child case SpaceChildRoom _)
      return RoomTextButton(
        child.child,
        onTap: widget.onRoomSelected,
        highlight: selectedRoom == child.child,
      );

    return Container();
  }
}
