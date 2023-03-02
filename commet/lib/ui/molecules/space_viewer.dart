import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/style/theme_extensions.dart';
import '../atoms/room_button.dart';
import '../atoms/room_list.dart';

class SpaceViewer extends StatefulWidget {
  SpaceViewer(this.space, {super.key, this.onRoomSelected, this.onRoomInsert});
  Space space;
  Stream<int>? onRoomInsert;

  void Function(int)? onRoomSelected;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer> with TickerProviderStateMixin {
  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    print("Setting state");
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                    child: RoomList(
                  widget.space.rooms,
                  expanderText: "Test Expander",
                  onInsertStream: widget.space.onRoomAdded.stream,
                  onUpdateStream: widget.space.onUpdate.stream,
                  onRoomSelected: widget.onRoomSelected,
                  expandable: false,
                  showHeader: true,
                  onRoomReordered: (oldIndex, newIndex) {
                    widget.space.reorderRooms(oldIndex, newIndex);
                  },
                )),
              ],
            ),
          )),
    );
  }
}
