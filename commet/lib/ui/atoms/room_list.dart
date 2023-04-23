import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/text_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;
import '../../client/client.dart';

class RoomList extends StatefulWidget {
  const RoomList(this.rooms,
      {super.key,
      this.onInsertStream,
      this.onUpdateStream,
      this.onRoomSelected,
      this.onRoomReordered,
      this.expandable = false,
      this.showHeader = false,
      this.expanderText});
  final bool expandable;
  final bool showHeader;
  final List<Room> rooms;
  final Stream<void>? onUpdateStream;
  final Stream<int>? onInsertStream;
  final String? expanderText;
  final void Function(int)? onRoomSelected;
  final void Function(int oldIndex, int newIndex)? onRoomReordered;
  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  StreamSubscription<int>? onInsertListener;
  StreamSubscription<void>? onUpdateListener;
  AnimationController? controller;
  bool expanded = false;
  bool editMode = false;
  int _selectedIndex = -1;

  @override
  void initState() {
    onUpdateListener = widget.onUpdateStream?.listen((event) {
      setState(() {});
    });

    onInsertListener = widget.onInsertStream?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
    });

    _count = widget.rooms.length;
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));

    super.initState();
  }

  @override
  void dispose() {
    onInsertListener?.cancel();
    onUpdateListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.showHeader) header(),
          if (widget.expandable)
            tiamat.TextButton(
              widget.expanderText!,
              onTap: toggleExpansion,
              icon: m.Icons.expand_circle_down,
            ),
          if (!widget.expandable) listRooms(),
          if (widget.expandable)
            SizeTransition(
              sizeFactor: controller!,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: listRooms(),
              ),
            ),
        ],
      ),
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            tiamat.Text.label("Rooms"),
          ],
        ),
      ),
    );
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  Widget listRooms() {
    if (editMode) {
      return m.ReorderableListView.builder(
        itemBuilder: (context, index) {
          return TextButton(
            icon: m.Icons.tag,
            widget.rooms[index].displayName,
            key: widget.rooms[index].key,
          );
        },
        itemCount: widget.rooms.length,
        onReorder: (oldIndex, newIndex) {
          widget.onRoomReordered?.call(oldIndex, newIndex);
        },
        shrinkWrap: true,
      );
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _count,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, i, animation) => SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
          child: SizedBox(
            height: 37,
            child: TextButton(
              widget.rooms[i].displayName,
              highlighted: _selectedIndex == i,
              icon: m.Icons.tag,
              onTap: () {
                widget.onRoomSelected?.call(i);
                setState(() {
                  _selectedIndex = i;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  void toggleExpansion() {
    setState(() {
      expanded = !expanded;
      if (expanded) controller?.forward(from: controller!.value);
      if (!expanded) controller?.reverse(from: controller!.value);
    });
  }
}
