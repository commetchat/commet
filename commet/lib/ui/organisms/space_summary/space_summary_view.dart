import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/utils/common_animation.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import '../../atoms/tooltip.dart' as t;
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
      this.visibility,
      this.spaceColor,
      this.showSpaceSettingsButton = false,
      this.openSpaceSettings,
      this.onAddRoomButtonTap,
      this.onRoomTap,
      this.onRoomSettingsButtonTap});
  final String displayName;
  final String? topic;
  final Future<void> Function(String roomId)? joinRoom;
  final List<RoomPreview>? childPreviews;
  final Stream<void>? onSpaceUpdated;
  final Stream<int>? onChildPreviewAdded;
  final Stream<StaleRoomInfo>? onChildPreviewRemoved;
  final Stream<int>? onChildPreviewsUpdated;
  final Stream<int>? onRoomAdded;
  final Stream<int>? onRoomRemoved;
  final RoomVisibility? visibility;
  final ImageProvider? avatar;
  final Color? spaceColor;
  final List<Room>? rooms;
  final Function? openSpaceSettings;
  final Function(Room room)? onRoomSettingsButtonTap;
  final Function(Room room)? onRoomTap;
  final Function()? onAddRoomButtonTap;
  final bool showSpaceSettingsButton;
  @override
  State<SpaceSummaryView> createState() => SpaceSummaryViewState();
}

class SpaceSummaryViewState extends State<SpaceSummaryView> {
  int childPreviewCount = 0;
  int childCount = 0;

  final GlobalKey<AnimatedListState> _previewListKey =
      GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _roomListKey =
      GlobalKey<AnimatedListState>();

  static ValueKey spaceSettingsButtonKey =
      const ValueKey("SPACE_SUMMARY_SPACE_SETTINGS_BUTTON");

  StreamSubscription? previewAddedSubscription;
  StreamSubscription? previewRemovedSubscription;
  StreamSubscription? roomAddedSubscription;

  @override
  void initState() {
    setState(() {
      childPreviewCount = widget.childPreviews?.length ?? 0;
      childCount = widget.rooms?.length ?? 0;
    });

    previewAddedSubscription =
        widget.onChildPreviewAdded?.listen(onPreviewAdded);

    previewRemovedSubscription =
        widget.onChildPreviewRemoved?.listen(onPreviewRemoved);

    roomAddedSubscription = widget.onRoomAdded?.listen(onRoomAdded);

    super.initState();
  }

  @override
  void dispose() {
    previewAddedSubscription?.cancel();
    previewRemovedSubscription?.cancel();
    roomAddedSubscription?.cancel();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  spaceVisibility(),
                ],
              ),
              if (widget.showSpaceSettingsButton) buildSettingsButton()
            ],
          ),
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

  Padding buildSettingsButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: t.Tooltip(
        text: "Space settings",
        preferredDirection: AxisDirection.left,
        child: tiamat.CircleButton(
          key: spaceSettingsButtonKey,
          icon: Icons.settings,
          radius: BuildConfig.MOBILE ? 24 : 16,
          onPressed: () => widget.openSpaceSettings?.call(),
        ),
      ),
    );
  }

  Widget avatar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Avatar.extraLarge(
        image: widget.avatar,
        placeholderText: widget.displayName,
        placeholderColor: widget.spaceColor,
      ),
    );
  }

  Widget buildRoomList() {
    return Panel(
      header: "Rooms",
      mode: TileType.surfaceLow1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedList(
            initialItemCount: childCount,
            key: _roomListKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              var room = widget.rooms![index];
              return SizeTransition(
                  sizeFactor: CommonAnimations.easeOut(animation),
                  child: RoomPanel(
                    displayName: room.displayName,
                    avatar: room.avatar,
                    color: room.defaultColor,
                    showSettingsButton: room.permissions.canEditAnything,
                    onRoomSettingsButtonPressed: () {
                      widget.onRoomSettingsButtonTap?.call(room);
                    },
                    onTap: widget.onRoomTap != null
                        ? () {
                            widget.onRoomTap?.call(room);
                          }
                        : null,
                    recentEventBody: room.lastEvent?.body,
                    recentEventSender: room.lastEvent != null
                        ? room.client
                            .fetchPeer(room.lastEvent!.senderId)
                            .displayName
                        : null,
                    recentEventSenderColor: room.lastEvent != null
                        ? room.getColorOfUser(room.lastEvent!.senderId)
                        : null,
                  ));
            },
          ),
          t.Tooltip(
            text: "Add Room",
            preferredDirection: AxisDirection.left,
            child: tiamat.CircleButton(
              radius: BuildConfig.MOBILE ? 24 : 16,
              icon: Icons.add,
              onPressed: () => widget.onAddRoomButtonTap?.call(),
            ),
          )
        ],
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
              sizeFactor: CommonAnimations.easeOut(animation),
              child: RoomPanel(
                displayName: preview.displayName!,
                avatar: preview.avatar,
                topic: preview.topic,
                primaryButtonLabel: CommonStrings.promptJoin,
                color: preview.color,
                onPrimaryButtonPressed: () {
                  widget.joinRoom?.call(preview.roomId);
                },
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

  void onPreviewAdded(int index) {
    _previewListKey.currentState?.insertItem(index);
    setState(() {
      childPreviewCount++;
    });
  }

  void onPreviewRemoved(StaleRoomInfo staleRoomInfo) {
    childPreviewCount--;
    _previewListKey.currentState?.removeItem(
        staleRoomInfo.index,
        (context, animation) => SizeTransition(
            sizeFactor: CommonAnimations.easeIn(animation),
            child: RoomPanel(
              displayName: staleRoomInfo.name!,
              avatar: staleRoomInfo.avatar,
              topic: staleRoomInfo.topic,
              primaryButtonLabel: CommonStrings.promptJoin,
              onPrimaryButtonPressed: () => null,
            )));
  }

  void onRoomAdded(int event) {
    setState(() {
      _roomListKey.currentState?.insertItem(event);
      childCount++;
    });
  }
}
