import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:flutter/widgets.dart';

class SpaceSummary extends StatefulWidget {
  const SpaceSummary({super.key, required this.space});
  final Space space;
  @override
  State<SpaceSummary> createState() => _SpaceSummaryState();
}

class _SpaceSummaryState extends State<SpaceSummary> {
  @override
  Widget build(BuildContext context) {
    return SpaceSummaryView(
      displayName: widget.space.displayName,
      childPreviews: widget.space.childPreviews,
      onChildPreviewAdded: widget.space.onChildPreviewAdded.stream,
      avatar: widget.space.avatar,
      rooms: widget.space.rooms,
    );
  }

  Future<void> joinRoom(String roomId) {
    return widget.space.client.joinRoom(roomId);
  }
}
