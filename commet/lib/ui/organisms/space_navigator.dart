import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/molecules/space_viewer.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';

class SpaceNavigator extends StatefulWidget {
  SpaceNavigator(this.spaces, {super.key});
  List<Space> spaces;
  final double width = 70;

  @override
  State<SpaceNavigator> createState() => _SpaceNavigatorState();
}

class _SpaceNavigatorState extends State<SpaceNavigator> {
  int selectedIndex = 0;
  int roomIndex = 0;
  Space? selectedSpace;
  Room? selectedRoom;

  @override
  Widget build(BuildContext context) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            width: widget.width,
            child: SpaceSelector(
              widget.spaces,
              onSelected: (index) {
                setState(() {
                  selectedIndex = index;
                  selectedSpace = widget.spaces[index];
                  roomIndex = 0;
                });
              },
            ),
          ),
          if (selectedSpace != null)
            SizedBox(
                width: 300,
                child: Container(
                    child: SpaceViewer(
                  selectedSpace!,
                  key: selectedSpace!.key,
                  onRoomSelected: (i) => setState(() {
                    roomIndex = i;
                    selectedRoom = selectedSpace!.rooms[roomIndex];
                  }),
                ))),
          if (selectedRoom != null) Flexible(child: TimelineViewer(key: selectedRoom!.key, room: selectedRoom!))
        ]);
  }
}
