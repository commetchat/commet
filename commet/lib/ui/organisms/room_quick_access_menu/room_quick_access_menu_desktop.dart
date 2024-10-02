import 'package:commet/client/client.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomQuickAccessMenuViewDesktop extends StatelessWidget {
  const RoomQuickAccessMenuViewDesktop({required this.room, super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    final menu = RoomQuickAccessMenu(room: room);

    return Row(
      children: menu.actions
          .map((e) => SizedBox(
              width: 25,
              height: 25,
              child: tiamat.IconButton(
                icon: e.icon,
                onPressed: () => e.action?.call(context),
              )))
          .toList(),
    );
  }
}
