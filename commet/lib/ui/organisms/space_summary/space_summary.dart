import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/space_banner/space_banner_component.dart';
import 'package:commet/client/components/space_color_scheme/space_color_scheme_component.dart';
import 'package:commet/client/space_child.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/ui/pages/settings/space_settings_page.dart';
import 'package:flutter/material.dart';
import '../../navigation/navigation_utils.dart';

class SpaceSummary extends StatefulWidget {
  const SpaceSummary(
      {super.key, required this.space, this.onRoomTap, this.onSpaceTap});
  final Space space;
  final Function(Room room)? onRoomTap;
  final Function(Space space)? onSpaceTap;
  @override
  State<SpaceSummary> createState() => _SpaceSummaryState();
}

class _SpaceSummaryState extends State<SpaceSummary> {
  StreamSubscription? onUpdateSubscription;

  @override
  void initState() {
    onUpdateSubscription = widget.space.onUpdate.listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    onUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    var comp = widget.space.getComponent<SpaceColorSchemeComponent>();
    if (comp != null) {
      colorScheme = comp.scheme;
    }

    var banner = widget.space.getComponent<SpaceBannerComponent>();

    return SpaceSummaryView(
      space: widget.space,
      displayName: widget.space.displayName,
      avatar: widget.space.avatar,
      visibility: widget.space.visibility,
      joinRoom: joinRoom,
      banner: banner?.banner,
      openSpaceSettings: openSpaceSettings,
      onRoomSettingsButtonTap: openRoomSettings,
      spaceColor: widget.space.color,
      onRoomTap: widget.onRoomTap,
      showSpaceSettingsButton: widget.space.permissions.canEditAnything,
      onAddRoomButtonTap: onAddRoomButtonTap,
      canAddRoom: widget.space.permissions.canEditChildren,
      onSpaceTap: widget.onSpaceTap,
      colorScheme: colorScheme,
    );
  }

  Future<void> joinRoom(String roomId) {
    return widget.space.client.joinRoom(roomId);
  }

  Future<void> createRoom(Client client, CreateRoomArgs args) async {
    var room = await client.createRoom(args);
    await widget.space.setSpaceChildRoom(room);
  }

  void openSpaceSettings() {
    NavigationUtils.navigateTo(context, SpaceSettingsPage(space: widget.space));
  }

  void openRoomSettings(Room room) {
    NavigationUtils.navigateTo(context, RoomSettingsPage(room: room));
  }

  void onAddRoomButtonTap() async {
    var room = await GetOrCreateRoom.show(
      widget.space.client,
      context,
      joinRoom: false,
      showAllRoomTypes: true,
      existingRoomsRemoveWhere: (child) {
        if (child case SpaceChildSpace s) {
          if (s.child == widget.space) return true;
        }

        if (widget.space.children.any((i) => i.id == child.id)) {
          return true;
        }

        return false;
      },
    );

    if (room is SpaceChildRoom) {
      widget.space.setSpaceChildRoom(room.child);
    }

    if (room is SpaceChildSpace) {
      widget.space.setSpaceChildSpace(room.child);
    }
  }
}
