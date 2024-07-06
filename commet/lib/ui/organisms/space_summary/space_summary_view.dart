import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/utils/common_animation.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceSummaryView extends StatefulWidget {
  const SpaceSummaryView(
      {super.key,
      required this.displayName,
      this.topic,
      this.joinRoom,
      this.rooms,
      this.spaces,
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
      this.canAddRoom = false,
      this.onSpaceTap,
      this.onRoomSettingsButtonTap});
  final String displayName;
  final String? topic;
  final Future<void> Function(String roomId)? joinRoom;
  final List<RoomPreview>? childPreviews;
  final Stream<void>? onSpaceUpdated;
  final Stream<int>? onChildPreviewAdded;
  final Stream<int>? onChildPreviewRemoved;
  final Stream<int>? onChildPreviewsUpdated;
  final Stream<int>? onRoomAdded;
  final Stream<int>? onRoomRemoved;
  final RoomVisibility? visibility;
  final ImageProvider? avatar;
  final Color? spaceColor;
  final List<Room>? rooms;
  final List<Space>? spaces;
  final Function? openSpaceSettings;
  final Function(Room room)? onRoomSettingsButtonTap;
  final Function(Room room)? onRoomTap;
  final Function(Space space)? onSpaceTap;
  final Function()? onAddRoomButtonTap;
  final bool showSpaceSettingsButton;
  final bool canAddRoom;
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
  StreamSubscription? roomRemovedSubscription;

  String get tooltipSpaceSettings => Intl.message("Space settings",
      desc: "Tooltip for the button that opens space settings",
      name: "tooltipSpaceSettings");

  String get tooltipAddRoom => Intl.message("Add room",
      desc: "Tooltip for the button that adds a new room to a space",
      name: "tooltipAddRoom");

  String get labelSpaceRoomsList => Intl.message("Rooms",
      desc: "Header label for the list of rooms in a space",
      name: "labelSpaceRoomsList");

  String get labelSpaceSubspacesList => Intl.message("Spaces",
      desc: "Header label for the list of child spaces in a space",
      name: "labelSpaceSubspacesList");

  String get labelSpaceAvailableRoomsList => Intl.message("Available rooms",
      desc:
          "Header label for the list of rooms in a space, which the user has not yet joined but are available",
      name: "labelSpaceAvailableRoomsList");

  String get labelSpaceVisibilityPublic => Intl.message("Public space",
      desc: "Label to display that the space is publically available",
      name: "labelSpaceVisibilityPublic");

  String get labelSpaceVisibilityPrivate => Intl.message("Private space",
      desc: "Label to display that the space is private",
      name: "labelSpaceVisibilityPrivate");

  String labelSpaceGettingText(spaceName) =>
      Intl.message("Welcome to \n\n # $spaceName",
          args: [spaceName],
          desc: "Greeting to the space, supports markdown formatting",
          name: "labelSpaceGettingText");

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

    roomRemovedSubscription = widget.onRoomRemoved?.listen(onRoomRemoved);

    super.initState();
  }

  @override
  void dispose() {
    previewAddedSubscription?.cancel();
    previewRemovedSubscription?.cancel();
    roomAddedSubscription?.cancel();
    roomRemovedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var pad = const EdgeInsets.fromLTRB(0, 4, 0, 4);

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
          if (childPreviewCount > 0)
            Padding(
              padding: pad,
              child: buildPreviewList(),
            ),
          if (widget.spaces?.isNotEmpty == true)
            Padding(
              padding: pad,
              child: buildSpaceList(),
            ),
          Padding(
            padding: pad,
            child: buildRoomList(),
          ),
        ],
      ),
    );
  }

  Padding buildSettingsButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: tiamat.Tooltip(
        text: tooltipSpaceSettings,
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
      header: labelSpaceRoomsList,
      mode: TileType.surfaceContainer,
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
              return buildRoomPanel(animation, room);
            },
          ),
          tiamat.Tooltip(
            text: tooltipAddRoom,
            preferredDirection: AxisDirection.left,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
              child: tiamat.CircleButton(
                radius: BuildConfig.MOBILE ? 24 : 16,
                icon: Icons.add,
                onPressed: () => widget.onAddRoomButtonTap?.call(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildSpaceList() {
    return Panel(
      header: labelSpaceSubspacesList,
      mode: TileType.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.spaces!.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var space = widget.spaces![index];
              return RoomPanel(
                displayName: space.displayName,
                color: space.color,
                body: space.topic,
                avatar: space.avatar,
                onTap: () => widget.onSpaceTap?.call(space),
              );
            },
          )
        ],
      ),
    );
  }

  SizeTransition buildRoomPanel(Animation<double> animation, Room room) {
    return SizeTransition(
        sizeFactor: CommonAnimations.easeOut(animation),
        child: RoomPanel(
          displayName: room.displayName,
          avatar: room.avatar,
          color: room.defaultColor,
          onTap: widget.onRoomTap != null
              ? () {
                  widget.onRoomTap?.call(room);
                }
              : null,
          body: room.lastEvent?.body,
          recentEventSender: room.lastEvent != null
              ? room.getMemberOrFallback(room.lastEvent!.senderId).displayName
              : null,
          recentEventSenderColor: room.lastEvent != null
              ? room.getColorOfUser(room.lastEvent!.senderId)
              : null,
        ));
  }

  Widget buildPreviewList() {
    return Panel(
      header: labelSpaceAvailableRoomsList,
      mode: TileType.surfaceContainer,
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
                displayName: preview.displayName,
                avatar: preview.avatar,
                primaryButtonLabel: CommonStrings.promptJoin,
                body: preview.topic,
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
      MarkdownBody(data: labelSpaceGettingText(widget.displayName)),
      if (widget.topic != null) tiamat.Text.label(widget.topic!),
    ]);
  }

  Widget spaceVisibility() {
    IconData data =
        widget.visibility == RoomVisibility.public ? Icons.public : Icons.lock;
    String text = widget.visibility == RoomVisibility.public
        ? labelSpaceVisibilityPublic
        : labelSpaceVisibilityPrivate;
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

  void onPreviewRemoved(int index) {
    childPreviewCount--;
    var toBeRemoved = widget.childPreviews![index];

    var info = StaleRoomInfo(
        name: toBeRemoved.displayName,
        avatar: toBeRemoved.avatar,
        topic: toBeRemoved.topic);

    _previewListKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
            sizeFactor: CommonAnimations.easeIn(animation),
            child: RoomPanel(
              displayName: info.name!,
              avatar: info.avatar,
              body: info.topic,
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

  void onRoomRemoved(int event) {
    var room = widget.rooms![event];
    if (mounted)
      setState(() {
        _roomListKey.currentState?.removeItem(
            event, (context, animation) => buildRoomPanel(animation, room));
        childCount--;
      });
  }
}
