import 'dart:async';

import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
      this.onRemoveStream,
      this.onRoomReordered,
      this.expandable = false,
      this.showHeader = false,
      this.expanderText,
      this.onChildUpdatedStream,
      this.onRoomSelectionChanged});
  final bool expandable;
  final bool showHeader;
  final List<Room> rooms;
  final Stream<void>? onUpdateStream;
  final Stream<Room>? onChildUpdatedStream;
  final Stream<int>? onInsertStream;
  final Stream<int>? onRemoveStream;
  final String? expanderText;
  final void Function(int)? onRoomSelected;
  final void Function(int oldIndex, int newIndex)? onRoomReordered;
  final Stream<Room>? onRoomSelectionChanged;
  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  StreamSubscription<int>? onInsertListener;
  StreamSubscription<int>? onRemoveListener;
  StreamSubscription<void>? onUpdateListener;
  StreamSubscription<Room>? onChildUpdatedListener;
  StreamSubscription<Room>? onRoomSelectionChangedListener;
  AnimationController? controller;
  bool expanded = false;
  bool editMode = false;
  int _selectedIndex = -1;

  String get labelRoomsList => Intl.message("Rooms",
      desc: "Header label for the list of rooms", name: "labelRoomsList");

  @override
  void initState() {
    onUpdateListener = widget.onUpdateStream?.listen((event) {
      setState(() {});
    });

    onInsertListener = widget.onInsertStream?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
    });

    onRemoveListener = widget.onRemoveStream?.listen(onRoomRemoved);

    onChildUpdatedListener = widget.onChildUpdatedStream?.listen((event) {
      _listKey.currentState?.setState(() {});
    });

    onRoomSelectionChangedListener =
        widget.onRoomSelectionChanged?.listen((room) {
      if (_selectedIndex != -1 && widget.rooms[_selectedIndex] == room) return;

      setState(() {
        _selectedIndex = widget.rooms.indexOf(room);
      });
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
    onRoomSelectionChangedListener?.cancel();
    onChildUpdatedListener?.cancel();
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
          children: [
            tiamat.Text.label(labelRoomsList),
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
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, i, animation) {
        var room = widget.rooms[i];
        return buildRoomButton(
          animation,
          room,
          context,
          iconColor: getIconColor(context, i),
          textColor: getTextColor(context, i),
          highlighted: _selectedIndex == i,
          onTap: () {
            widget.onRoomSelected?.call(i);
            setState(() {
              _selectedIndex = i;
            });
          },
        );
      },
    );
  }

  SizeTransition buildRoomButton(
    Animation<double> animation,
    Room room,
    BuildContext context, {
    Color? iconColor,
    Color? textColor,
    bool highlighted = false,
    void Function()? onTap,
  }) {
    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
        child: SizedBox(
          height: 37,
          child: TextButton(room.displayName,
              highlighted: highlighted,
              icon: m.Icons.tag,
              iconColor: iconColor,
              textColor: textColor,
              footer: room.displayHighlightedNotificationCount > 0
                  ? NotificationBadge(room.displayHighlightedNotificationCount)
                  : room.displayNotificationCount > 0
                      ? const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: DotIndicator(),
                        )
                      : null,
              onTap: onTap),
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

  Color getTextColor(BuildContext context, int index) {
    if (index == _selectedIndex)
      return m.Theme.of(context).colorScheme.onSurface;

    var room = widget.rooms[index];

    if (room.notificationCount > 0 || room.highlightedNotificationCount > 0)
      return m.Theme.of(context).colorScheme.onSurface;

    return m.Theme.of(context).colorScheme.secondary;
  }

  Color getIconColor(BuildContext context, int index) {
    var room = widget.rooms[index];

    if (room.notificationCount > 0 || room.highlightedNotificationCount > 0)
      return m.Theme.of(context).colorScheme.onSurface;

    return m.Theme.of(context).colorScheme.secondary;
  }

  void onRoomRemoved(int index) {
    if (mounted) {
      var room = widget.rooms[index];
      var iconColor = getIconColor(context, index);
      var color = getTextColor(context, index);

      if (index == _selectedIndex) {
        _selectedIndex = -1;
      }

      _listKey.currentState?.removeItem(
          index,
          (context, animation) => buildRoomButton(animation, room, context,
              iconColor: iconColor, textColor: color));
      _count--;
    }
  }
}
