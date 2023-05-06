import 'dart:async';

import 'package:flutter/material.dart';

import '../../client/client.dart';
import '../atoms/room_list.dart';

class SpaceViewer extends StatefulWidget {
  const SpaceViewer(this.space,
      {super.key,
      this.onRoomSelected,
      this.onRoomInsert,
      this.onRoomSelectionChanged});
  final Space space;
  final Stream<int>? onRoomInsert;
  final Stream<Room>? onRoomSelectionChanged;
  final void Function(int)? onRoomSelected;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: RoomList(
          widget.space.rooms,
          expanderText: "Test Expander",
          onInsertStream: widget.space.onRoomAdded.stream,
          onUpdateStream: widget.space.onUpdate.stream,
          onRoomSelected: widget.onRoomSelected,
          onRoomSelectionChanged: widget.onRoomSelectionChanged,
          expandable: false,
          showHeader: true,
          onRoomReordered: (oldIndex, newIndex) {
            widget.space.reorderRooms(oldIndex, newIndex);
          },
        ));
  }
}
