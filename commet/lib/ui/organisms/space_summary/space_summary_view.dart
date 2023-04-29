import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceSummaryView extends StatefulWidget {
  const SpaceSummaryView(
      {super.key,
      required this.displayName,
      this.topic,
      this.joinRoom,
      this.rooms,
      this.avatar,
      this.childPreviews,
      this.onChildPreviewAdded,
      this.onChildPreviewRemoved,
      this.onChildPreviewsUpdated,
      this.onSpaceUpdated,
      this.onRoomAdded,
      this.onRoomRemoved,
      this.visibility});
  final String displayName;
  final String? topic;
  final Future<void> Function(String roomId)? joinRoom;
  final List<PreviewData>? childPreviews;
  final Stream<void>? onSpaceUpdated;
  final Stream<int>? onChildPreviewAdded;
  final Stream<int>? onChildPreviewRemoved;
  final Stream<int>? onChildPreviewsUpdated;
  final Stream<int>? onRoomAdded;
  final Stream<int>? onRoomRemoved;
  final RoomVisibility? visibility;
  final ImageProvider? avatar;
  final List<Room>? rooms;
  @override
  State<SpaceSummaryView> createState() => _SpaceSummaryViewState();
}

class _SpaceSummaryViewState extends State<SpaceSummaryView> {
  int childPreviewCount = 0;
  int childCount = 0;

  final GlobalKey<AnimatedListState> _previewListKey =
      GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _roomListKey =
      GlobalKey<AnimatedListState>();

  StreamSubscription? previewAddedSubscription;

  @override
  void initState() {
    setState(() {
      childPreviewCount = widget.childPreviews?.length ?? 0;
      childCount = widget.rooms?.length ?? 0;
    });

    previewAddedSubscription =
        widget.onChildPreviewAdded?.listen(onPreviewAdded);

    super.initState();
  }

  @override
  void dispose() {
    previewAddedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar(),
          buildHeader(),
          spaceVisibility(),
          if (childPreviewCount > 0) buildPreviewList(),
          if (childPreviewCount > 0)
            const SizedBox(
              height: 10,
            ),
          buildRoomList(),
        ],
      ),
    );
  }

  Widget avatar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Avatar.extraLarge(
        image: widget.avatar,
        placeholderText: widget.displayName,
      ),
    );
  }

  Widget buildRoomList() {
    return Panel(
      header: "Rooms",
      mode: TileType.surfaceLow1,
      child: AnimatedList(
        initialItemCount: childCount,
        key: _roomListKey,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index, animation) {
          var room = widget.rooms![index];
          return SizeTransition(
              sizeFactor: animation,
              child: RoomPanel(
                displayName: room.displayName,
                avatar: room.avatar,
              ));
        },
      ),
    );
  }

  Widget buildPreviewList() {
    return Panel(
      header: "Available rooms",
      mode: TileType.surfaceLow1,
      child: AnimatedList(
        initialItemCount: childPreviewCount,
        key: _previewListKey,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index, animation) {
          var preview = widget.childPreviews![index];
          return SizeTransition(
              sizeFactor: animation,
              child: RoomPanel(
                displayName: preview.displayName!,
                avatar: preview.avatar,
                topic: preview.topic,
                showJoinButton: true,
              ));
        },
      ),
    );
  }

  Widget buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const tiamat.Text.label("Welcome to"),
      tiamat.Text.largeTitle(widget.displayName),
      if (widget.topic != null) tiamat.Text.label(widget.topic!),
    ]);
  }

  void onPreviewAdded(int index) {
    _previewListKey.currentState?.insertItem(index);
    setState(() {
      childPreviewCount++;
    });
  }

  Widget spaceVisibility() {
    IconData data =
        widget.visibility == RoomVisibility.public ? Icons.public : Icons.lock;
    String text = widget.visibility == RoomVisibility.public
        ? "Public space"
        : "Private space";
    return Row(
      children: [
        Icon(data),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.label(text),
        )
      ],
    );
  }
}
