import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/room_text_button.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceList extends StatefulWidget {
  const SpaceList(this.space,
      {this.onRoomSelected,
      this.onChildAdded,
      this.onChildRemoved,
      this.onChildUpdated,
      this.isTopLevel = true,
      super.key});
  final Function(Room room)? onRoomSelected;

  final Stream<void>? onChildAdded;
  final Stream<void>? onChildRemoved;
  final Stream<void>? onChildUpdated;
  final bool isTopLevel;

  final Space space;

  @override
  State<SpaceList> createState() => _SpaceListState();
}

class _SpaceListState extends State<SpaceList> {
  late List<Space> subSpaces;

  late List<StreamSubscription> subs;

  Room? selectedRoom;
  String get labelRoomsList => Intl.message("Rooms",
      desc: "Header label for the list of rooms", name: "labelRoomsList");

  @override
  void initState() {
    subSpaces = widget.space.subspaces;
    EventBus.onSelectedRoomChanged.stream.listen(onRoomSelected);

    subs = [
      widget.space.onUpdate.listen(onSpaceUpdated),
      if (widget.onChildAdded != null)
        widget.onChildAdded!.listen(onSpaceUpdated),
      if (widget.onChildRemoved != null)
        widget.onChildRemoved!.listen(onSpaceUpdated),
      if (widget.onChildUpdated != null)
        widget.onChildUpdated!.listen(onSpaceUpdated),
      for (var room in widget.space.rooms) room.onUpdate.listen(onRoomUpdated),
    ];

    super.initState();
  }

  void onSpaceUpdated(void event) {
    setState(() {
      subSpaces = widget.space.subspaces;
    });
  }

  void onRoomUpdated(void event) {
    setState(() {});
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void onRoomSelected(Room? event) {
    setState(() {
      selectedRoom = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (subSpaces.isNotEmpty)
          Padding(
              padding: EdgeInsets.fromLTRB(0, widget.isTopLevel ? 12 : 0, 0, 0),
              child: ImplicitlyAnimatedList(
                itemData: subSpaces,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                initialAnimation: false,
                itemBuilder: (context, data) {
                  return tiamat.TextButtonExpander(data.displayName,
                      initiallyExpanded: true,
                      childrenPadding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                      iconColor: Theme.of(context).colorScheme.secondary,
                      textColor: Theme.of(context).colorScheme.secondary,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                          child: SpaceList(
                            data,
                            isTopLevel: false,
                            onRoomSelected: widget.onRoomSelected,
                          ),
                        )
                      ]);
                },
              )),
        if (widget.space.rooms.isNotEmpty) roomsList()
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
        return SizedBox(
            height: 37,
            child: RoomTextButton(
              data,
              onTap: widget.onRoomSelected,
              highlight: selectedRoom == data,
            ));
      },
    );
  }
}
