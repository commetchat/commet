import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceSummaryView extends StatefulWidget {
  const SpaceSummaryView(
      {super.key,
      required this.space,
      required this.displayName,
      this.topic,
      this.joinRoom,
      this.avatar,
      this.onSpaceUpdated,
      this.visibility,
      this.spaceColor,
      this.showSpaceSettingsButton = false,
      this.openSpaceSettings,
      this.onAddRoomButtonTap,
      this.onRoomTap,
      this.canAddRoom = false,
      this.onSpaceTap,
      this.colorScheme,
      this.onRoomSettingsButtonTap});

  final Space space;
  final String displayName;
  final String? topic;
  final Future<void> Function(String roomId)? joinRoom;
  final Stream<void>? onSpaceUpdated;
  final RoomVisibility? visibility;
  final ImageProvider? avatar;
  final Color? spaceColor;
  final Function? openSpaceSettings;
  final Function(Room room)? onRoomSettingsButtonTap;
  final Function(Room room)? onRoomTap;
  final Function(Space space)? onSpaceTap;
  final Function()? onAddRoomButtonTap;
  final bool showSpaceSettingsButton;
  final bool canAddRoom;
  final ColorScheme? colorScheme;
  @override
  State<SpaceSummaryView> createState() => SpaceSummaryViewState();
}

class SpaceSummaryViewState extends State<SpaceSummaryView> {
  static ValueKey spaceSettingsButtonKey =
      const ValueKey("SPACE_SUMMARY_SPACE_SETTINGS_BUTTON");

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

  late List<Space> subspaces;
  late List<Room> rooms;
  late List<RoomPreview> previews;

  late List<StreamSubscription> subs;

  @override
  void initState() {
    subspaces = widget.space.subspaces;
    rooms = widget.space.rooms;
    previews = widget.space.childPreviews;

    subs = [
      widget.space.onChildRoomPreviewAdded
          .listen((_) => onPreviewListChanged()),
      widget.space.onChildRoomPreviewsUpdated
          .listen((_) => onPreviewListChanged()),
      widget.space.onChildRoomPreviewRemoved
          .listen((_) => onPreviewListChanged()),
      widget.space.onRoomAdded.listen((_) => onRoomListChanged()),
      widget.space.onRoomRemoved.listen((_) => onRoomListChanged()),
      widget.space.onChildSpaceAdded.listen((_) => onSpaceListChanged()),
      widget.space.onChildSpaceRemoved.listen((_) => onSpaceListChanged()),
    ];
    super.initState();
  }

  void onPreviewListChanged() {
    setState(() {
      previews = widget.space.childPreviews;
    });
  }

  void onRoomListChanged() {
    setState(() {
      rooms = widget.space.rooms;
    });
  }

  void onSpaceListChanged() {
    setState(() {
      subspaces = widget.space.subspaces;
    });
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var pad = const EdgeInsets.fromLTRB(0, 4, 0, 4);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        avatarAndBanner(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
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
              if (previews.isNotEmpty)
                Padding(
                  padding: pad,
                  child: buildPreviewList(),
                ),
              if (subspaces.isNotEmpty == true)
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
        ),
      ],
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

  Widget avatarAndBanner() {
    var colorScheme = widget.colorScheme ?? Theme.of(context).colorScheme;

    return Stack(
      children: [
        Padding(
          padding: Layout.desktop
              ? EdgeInsetsGeometry.only(left: 8, right: 8)
              : EdgeInsetsGeometry.zero,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))),
              child: ScaledSafeArea(
                bottom: false,
                left: false,
                right: false,
                top: true,
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                ),
              )),
        ),
        Align(
          alignment: AlignmentGeometry.center,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
              child: ScaledSafeArea(
                child: Avatar.extraLarge(
                  border: BoxBorder.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 10,
                      style: BorderStyle.solid,
                      strokeAlign: 0.5),
                  image: widget.avatar,
                  placeholderText: widget.displayName,
                  placeholderColor: widget.spaceColor,
                ),
              )),
        ),
      ],
    );
  }

  Widget buildRoomList() {
    return Panel(
      header: labelSpaceRoomsList,
      mode: TileType.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (rooms.isNotEmpty)
            ImplicitlyAnimatedList(
              padding: EdgeInsets.all(0),
              key: ValueKey("animated-list-rooms-${widget.space.identifier}"),
              initialAnimation: false,
              shrinkWrap: true,
              itemData: rooms,
              itemBuilder: (context, data) {
                return buildRoomPanel(data);
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
          ImplicitlyAnimatedList(
            padding: EdgeInsets.all(0),
            key: ValueKey(
                "animated-list-child-spaces-${widget.space.identifier}"),
            itemData: subspaces,
            initialAnimation: false,
            shrinkWrap: true,
            itemBuilder: (context, space) {
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

  Widget buildRoomPanel(Room room) {
    return RoomPanel(
      displayName: room.displayName,
      avatar: room.avatar,
      color: room.defaultColor,
      onTap: widget.onRoomTap != null
          ? () {
              widget.onRoomTap?.call(room);
            }
          : null,
      body: room.lastEvent?.plainTextBody,
      recentEventSender: room.lastEvent != null
          ? room.getMemberOrFallback(room.lastEvent!.senderId).displayName
          : null,
      recentEventSenderColor: room.lastEvent != null
          ? room.getColorOfUser(room.lastEvent!.senderId)
          : null,
    );
  }

  Widget buildPreviewList() {
    return Panel(
        header: labelSpaceAvailableRoomsList,
        mode: TileType.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ImplicitlyAnimatedList(
                padding: EdgeInsets.all(0),
                key: ValueKey(
                    "animated-list-child-previews-${widget.space.identifier}"),
                initialAnimation: false,
                itemData: previews,
                shrinkWrap: true,
                itemBuilder: (context, preview) {
                  return RoomPanel(
                    displayName: preview.displayName,
                    avatar: preview.avatar,
                    primaryButtonLabel: CommonStrings.promptJoin,
                    body: preview.topic,
                    color: preview.color,
                    onPrimaryButtonPressed: () async {
                      await widget.joinRoom?.call(preview.roomId);
                    },
                  );
                }),
          ],
        ));
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
}
