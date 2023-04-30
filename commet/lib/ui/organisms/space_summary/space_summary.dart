import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/settings/space_settings_page.dart';
import 'package:flutter/widgets.dart';

import '../../navigation/navigation_utils.dart';

class SpaceSummary extends StatefulWidget {
  const SpaceSummary({super.key, required this.space});
  final Space space;
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
    );
  }

  Future<void> joinRoom(String roomId) {
    return widget.space.client.joinRoom(roomId);
  }

  void openSpaceSettings() {
    NavigationUtils.navigateTo(context, SpaceSettingsPage(space: widget.space));
  }
}
