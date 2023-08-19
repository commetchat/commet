import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/add_space_or_room/add_space_or_room.dart';
import 'package:commet/ui/pages/settings/room_settings_page.dart';
import 'package:commet/ui/pages/settings/space_settings_page.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:flutter/widgets.dart';

import '../../navigation/navigation_utils.dart';

class SpaceSummary extends StatefulWidget {
  const SpaceSummary({super.key, required this.space, this.onRoomTap});
  final Space space;
  final Function(Room room)? onRoomTap;
  @override
  State<SpaceSummary> createState() => _SpaceSummaryState();
}

class _SpaceSummaryState extends State<SpaceSummary> {
  StreamSubscription? onUpdateSubscription;

  @override
  void initState() {
    onUpdateSubscription = widget.space.onUpdate.stream.listen((_) {
      setState(() {});
    });

    if (widget.space.avatar is LODImageProvider) {
      (widget.space.avatar as LODImageProvider).fetchFullRes();
    }

    super.initState();
  }

  @override
  void dispose() {
    onUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpaceSummaryView(
      displayName: widget.space.displayName,
      childPreviews: widget.space.childPreviews,
      onChildPreviewAdded: widget.space.onChildPreviewAdded.stream,
      onChildPreviewRemoved: widget.space.onChildPreviewRemoved.stream,
      onRoomAdded: widget.space.onRoomAdded.stream,
      avatar: widget.space.avatar,
      rooms: widget.space.rooms,
      joinRoom: joinRoom,
      openSpaceSettings: openSpaceSettings,
      onRoomSettingsButtonTap: openRoomSettings,
      spaceColor: widget.space.color,
      onRoomTap: widget.onRoomTap,
      showSpaceSettingsButton: widget.space.permissions.canEditAnything,
      onAddRoomButtonTap: onAddRoomButtonTap,
    );
  }

  Future<void> joinRoom(String roomId) {
    return widget.space.client.joinRoom(roomId);
  }

  void openSpaceSettings() {
    NavigationUtils.navigateTo(context, SpaceSettingsPage(space: widget.space));
  }

  openRoomSettings(Room room) {
    NavigationUtils.navigateTo(context, RoomSettingsPage(room: room));
  }

  onAddRoomButtonTap() {
    AdaptiveDialog.show(context,
        builder: (_) => AddSpaceOrRoom.askCreateOrExistingRoom(
              client: widget.space.client,
              rooms: widget.space.client
                  .getEligibleRoomsForSpace(widget.space)
                  .toList(),
              onRoomCreated: (Room room) async {
                widget.space.setSpaceChildRoom(room);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              onRoomsSelected: (rooms) {
                for (var room in rooms) {
                  widget.space.setSpaceChildRoom(room);
                }
                Navigator.pop(context);
              },
            ),
        title: "Add Room to Space");
  }
}
