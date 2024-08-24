import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomQuickAccessMenuViewMobile extends StatefulWidget {
  const RoomQuickAccessMenuViewMobile({required this.room, super.key});
  final Room room;

  @override
  State<RoomQuickAccessMenuViewMobile> createState() =>
      _RoomQuickAccessMenuViewMobileState();
}

class _RoomQuickAccessMenuViewMobileState
    extends State<RoomQuickAccessMenuViewMobile> {
  late RoomQuickAccessMenu menu;

  @override
  void initState() {
    menu = RoomQuickAccessMenu(room: widget.room);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: 50,
        child: ScaledSafeArea(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: menu.actions
              .map((e) => AspectRatio(
                    aspectRatio: 1,
                    child: SizedBox(
                        child: tiamat.IconButton(
                      icon: e.icon,
                      onPressed: () => e.action?.call(context),
                    )),
                  ))
              .toList(),
        )),
      ),
    );
  }
}
