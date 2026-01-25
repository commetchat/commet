import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomQuickAccessMenuViewDesktop extends StatefulWidget {
  const RoomQuickAccessMenuViewDesktop({required this.room, super.key});
  final Room room;

  @override
  State<RoomQuickAccessMenuViewDesktop> createState() =>
      _RoomQuickAccessMenuViewDesktopState();
}

class _RoomQuickAccessMenuViewDesktopState
    extends State<RoomQuickAccessMenuViewDesktop> {
  StreamSubscription? sub;

  @override
  void initState() {
    preferences.onSettingChanged.listen(onChanged);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final menu = RoomQuickAccessMenu(room: widget.room);

    return Row(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: menu.actions
          .map((e) => SizedBox(
              width: 40,
              height: 40,
              child: tiamat.IconButton(
                icon: e.icon,
                onPressed: () => e.action?.call(context),
              )))
          .toList(),
    );
  }

  void onChanged(event) {
    setState(() {});
  }
}
