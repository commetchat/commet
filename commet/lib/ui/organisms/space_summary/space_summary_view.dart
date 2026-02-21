import 'dart:async';
import 'dart:ui';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/space_child.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
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
      this.banner,
      this.visibility,
      this.spaceColor,
      this.showSpaceSettingsButton = false,
      this.onInviteButtonTap,
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
  final Future<void> Function(RoomPreview preview)? joinRoom;
  final Stream<void>? onSpaceUpdated;
  final RoomVisibility? visibility;
  final ImageProvider? avatar;
  final ImageProvider? banner;
  final Color? spaceColor;
  final Function? openSpaceSettings;
  final Function? onInviteButtonTap;
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

  String get labelSpaceVisibilityRestricted => Intl.message("Restricted space",
      desc: "Label to display that the space is restricted",
      name: "labelSpaceVisibilityRestricted");

  String labelSpaceGettingText(spaceName) =>
      Intl.message("Welcome to \n\n # $spaceName",
          args: [spaceName],
          desc: "Greeting to the space, supports markdown formatting",
          name: "labelSpaceGettingText");

  late List<RoomPreview> previews;

  late List<StreamSubscription> subs;

  late List<SpaceChild> children;

  bool canChangeOrder = true;
  bool orderChanged = false;
  bool orderChangeLoading = false;
  double? orderChangedProgress = null;

  @override
  void initState() {
    previews = widget.space.childPreviews;
    children = List.from(widget.space.children);

    canChangeOrder = widget.space.permissions.canEditChildren;

    final banner = widget.banner;
    if (banner is LODImageProvider) {
      banner.fetchFullRes();
    }

    if (widget.space.fullyLoaded == false) {
      widget.space.loadExtra();
    }

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
      children = List.from(widget.space.children);
    });
  }

  void onSpaceListChanged() {
    setState(() {
      children = List.from(widget.space.children);
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
    var baseTextTheme = TextTheme.of(context)
        .bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.secondary);

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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: labelSpaceGettingText(widget.displayName),
                          styleSheet: MarkdownStyleSheet(
                              h1Padding: EdgeInsets.zero,
                              pPadding: EdgeInsets.zero),
                        ),
                        if (widget.topic != null)
                          MarkdownBody(
                              data: widget.topic!,
                              imageBuilder: (uri, title, alt) {
                                if (uri.scheme == "mxc" &&
                                    widget.space.client is MatrixClient) {
                                  return SizedBox(
                                    height: 50,
                                    child: Image(
                                        image: MatrixMxcImage(
                                            uri,
                                            doFullres: true,
                                            doThumbnail: false,
                                            autoLoadFullRes: true,
                                            (widget.space.client
                                                    as MatrixClient)
                                                .matrixClient)),
                                  );
                                }

                                return Container();
                              },
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  LinkUtils.open(Uri.parse(href),
                                      context: context);
                                }
                              },
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(context))
                                  .copyWith(
                                a: baseTextTheme?.copyWith(
                                    color: Theme.of(context)
                                        .extension<ExtraColors>()
                                        ?.linkColor),
                                p: baseTextTheme,
                              )),
                        spaceVisibility(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      spacing: 8,
                      children: [
                        if (widget.onInviteButtonTap != null)
                          buildInviteButton(),
                        if (widget.showSpaceSettingsButton)
                          buildSettingsButton(),
                      ],
                    ),
                  )
                ],
              ),
              if (children.isNotEmpty ||
                  widget.space.permissions.canEditChildren)
                tiamat.Panel(
                  mode: TileType.surfaceContainerLow,
                  child: buildChildrenList(),
                ),
              if (previews.isNotEmpty) buildPreviewList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSettingsButton() {
    return tiamat.Tooltip(
      text: tooltipSpaceSettings,
      preferredDirection: AxisDirection.left,
      child: tiamat.CircleButton(
        key: spaceSettingsButtonKey,
        icon: Icons.settings,
        radius: BuildConfig.MOBILE ? 24 : 16,
        onPressed: () => widget.openSpaceSettings?.call(),
      ),
    );
  }

  Widget buildInviteButton() {
    return tiamat.Tooltip(
      text: "Invite",
      preferredDirection: AxisDirection.left,
      child: tiamat.CircleButton(
        key: spaceSettingsButtonKey,
        icon: Icons.person_add,
        radius: BuildConfig.MOBILE ? 24 : 16,
        onPressed: () => widget.onInviteButtonTap?.call(),
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
                  image: widget.banner != null
                      ? DecorationImage(
                          image: widget.banner!, fit: BoxFit.cover)
                      : null,
                  color: widget.banner == null ? colorScheme.secondary : null,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))),
              child: ScaledSafeArea(
                bottom: false,
                left: false,
                right: false,
                top: true,
                child: SizedBox(
                  height: 250,
                  // child: widget.banner != null
                  //     ? Image(
                  //         image: widget.banner!,
                  //         fit: BoxFit.cover,
                  //       )
                  //     : null,
                  width: double.infinity,
                ),
              )),
        ),
        Align(
          alignment: AlignmentGeometry.center,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 150, 0, 0),
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
                physics: NeverScrollableScrollPhysics(),
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
                      await widget.joinRoom?.call(preview);
                    },
                  );
                }),
          ],
        ));
  }

  Widget spaceVisibility() {
    IconData data = RoomVisibility.icon(widget.visibility);
    String text = switch (widget.visibility) {
      final RoomVisibilityPublic _ => labelSpaceVisibilityPublic,
      final RoomVisibilityPrivate _ => labelSpaceVisibilityPrivate,
      final RoomVisibilityRestricted _ => labelSpaceVisibilityRestricted,
      _ => "",
    };
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

  Widget buildChildrenList() {
    bool showHandles = Layout.desktop && canChangeOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: showHandles,
          itemBuilder: (context, index) {
            final item = children[index];
            var key = ValueKey(item.id);

            var pad = EdgeInsets.fromLTRB(0, 0, showHandles ? 50 : 0, 0);
            if (Layout.mobile) {
              return ReorderableDelayedDragStartListener(
                  key: key,
                  enabled: canChangeOrder,
                  index: index,
                  child: Padding(
                    padding: pad,
                    child: buildItem(item, widget.space),
                  ));
            } else {
              return ReorderableDragStartListener(
                  key: key,
                  enabled: canChangeOrder && orderChanged,
                  index: index,
                  child: Padding(
                    padding: pad,
                    child: buildItem(item, widget.space),
                  ));
            }
          },
          onReorderStart: (index) => HapticFeedback.mediumImpact(),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue =
                    Curves.easeOut.transform(animation.value);
                final double scale = lerpDouble(1, 1.03, animValue)!;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: child,
            );
          },
          itemCount: children.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }

            var i = children.removeAt(oldIndex);
            children.insert(newIndex, i);

            setState(() {
              orderChanged = true;
            });
          },
        ),
        if (orderChanged)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (!orderChangeLoading)
                  FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        children = widget.space.children;
                        orderChanged = false;
                      });
                    },
                    child: Icon(Icons.undo),
                  ),
                FloatingActionButton.small(
                  onPressed: () {
                    setState(() {
                      orderChangeLoading = true;
                    });

                    widget.space.setChildrenOrder(children,
                        onProgressChanged: (v) {
                      setState(() {
                        orderChangedProgress = v;
                      });
                    }).then((_) {
                      setState(() {
                        orderChanged = false;
                        orderChangeLoading = false;
                      });
                    });
                  },
                  child: orderChangeLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onSurface,
                            value: orderChangedProgress != null &&
                                    orderChangedProgress! > 0.1
                                ? orderChangedProgress
                                : null,
                          ))
                      : Icon(Icons.save),
                ),
              ],
            ),
          ),
        if (widget.space.permissions.canEditChildren)
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
    );
  }

  Widget buildItem(SpaceChild<dynamic> item, Space parent,
      {int depth = 0, int maxDepth = 5}) {
    Widget? result;

    if (item case SpaceChildRoom _) {
      final room = item.child;
      result = RoomPanel(
        displayName: room.displayName,
        avatar: room.avatar,
        color: room.defaultColor,
        onTap: orderChanged
            ? null
            : widget.onRoomTap != null
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
    } else if (item case SpaceChildSpace _) {
      result = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainer),
          child: tiamat.TextButtonExpander(item.child.displayName,
              textPadding: EdgeInsetsGeometry.all(20),
              icon: Icons.star, onNameTapped: () {
            widget.onSpaceTap?.call(item.child);
          },
              avatar: item.child.avatar,
              avatarPlaceholderColor: item.child.color,
              avatarPlaceholderText: item.child.displayName,
              avatarRadius: 24,
              childrenPadding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              initiallyExpanded: false,
              iconColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.secondary,
              children: depth >= maxDepth
                  ? []
                  : item.child.children
                      .map((i) => buildItem(i, item.child,
                          depth: depth + 1, maxDepth: maxDepth))
                      .toList()),
        ),
      );
    } else {
      result = Container();
    }

    return result;
  }
}
