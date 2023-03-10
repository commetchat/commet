import 'dart:async';

import 'package:commet/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/style/theme_extensions.dart';
import '../atoms/background.dart';
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
    return Padding(
        padding: EdgeInsets.all(s(8.0)),
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
        ));
  }
}
