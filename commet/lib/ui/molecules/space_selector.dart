import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/molecules/expanding_drop_target.dart';
import 'package:commet/ui/molecules/space_group_widget.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/utils/scaled_app.dart';

import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  const SpaceSelector(this.spaces,
      {super.key,
      this.onSelected,
      this.clearSelection,
      required this.width,
      this.shouldShowAvatarForSpace,
      this.header,
      this.footer});
  final List<SidebarEntry> spaces;
  final double width;
  final Widget? header;
  final Widget? footer;
  final void Function(Space space)? onSelected;
  final void Function()? clearSelection;
  final bool Function(Space space)? shouldShowAvatarForSpace;

  static EdgeInsets get padding => const EdgeInsets.fromLTRB(7, 0, 7, 0);

  @override
  State<SpaceSelector> createState() => SpaceSelectorState();
}

class SidebarEntryDrag {
  SidebarEntry entry;
  int originalIndex;
  String? currentFolder;

  SidebarEntryDrag(this.entry, this.originalIndex, {this.currentFolder});
}

class SpaceSelectorState extends State<SpaceSelector> {
  late List<SidebarEntry> items;

  @override
  void initState() {
    items = widget.spaces;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(SpaceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    setState(() {
      items = widget.spaces;
    });
  }

  Offset? dragPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics:
                  BuildConfig.ANDROID ? const BouncingScrollPhysics() : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    0, MediaQuery.of(context).scale().padding.top, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.header != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.header!,
                      ),
                    if (widget.header != null) const Seperator(),
                    ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(0),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var data = items[index];
                        return Column(
                          children: [
                            ExpandingDropTarget<SidebarEntryDrag>(
                              onWillAcceptWithDetails: (p0) {
                                return true;
                              },
                              onAcceptWithDetails: (p0) {
                                if (p0 is DragTargetDetails) {
                                  if (p0.data case SidebarEntryDrag data) {
                                    int i = index;
                                    if (data.originalIndex < index) {
                                      i -= 1;
                                    }

                                    handleSpaceOrderDropped(p0, i);
                                  }
                                }
                              },
                              position: dragPosition,
                            ),
                            buildItem(context, data, index),
                            if (index == widget.spaces.length - 1)
                              ExpandingDropTarget<SidebarEntryDrag>(
                                onWillAcceptWithDetails: (p0) {
                                  return true;
                                },
                                onAcceptWithDetails: (p0) {
                                  handleSpaceOrderDropped(p0, index);
                                },
                                position: dragPosition,
                              ),
                          ],
                        );
                      },
                    ),
                    if (widget.footer != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void handleSpaceOrderDropped(Object p0, int index) {
    if (p0 is DragTargetDetails) {
      if (p0.data case SidebarEntryDrag data) {
        if (data.currentFolder != null) {
          var space = (data.entry as SpaceSidebarEntry).space;

          var component = space.client.getComponent<SidebarEntriesComponent>()!;

          component.removeFromFolder(space, data.currentFolder!);
        }

        SidebarEntriesComponent.idToOrder.setIndex(data.entry.id, index);
      }
    }
  }

  Widget buildItem(context, data, int index) {
    if (data case SpaceSidebarEntry i) {
      return LongPressDraggable<SidebarEntryDrag>(
        data: SidebarEntryDrag(data, index),
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        childWhenDragging: Opacity(
          opacity: 0.1,
          child: buildSpaceIcon(
              width: widget.width,
              space: i.space,
              displayName: i.space.displayName,
              placeholderColor: i.space.color,
              onUpdate: i.space.onUpdate,
              avatar: i.space.avatar),
        ),
        feedback: SizedBox(
          width: widget.width,
          height: widget.width,
          child: Opacity(
            opacity: 0.5,
            child: buildSpaceIcon(
                width: widget.width,
                space: i.space,
                placeholderColor: i.space.color,
                displayName: i.space.displayName,
                onUpdate: i.space.onUpdate,
                avatar: i.space.avatar),
          ),
        ),
        hitTestBehavior: HitTestBehavior.opaque,
        child: DragTarget<SidebarEntryDrag>(onWillAcceptWithDetails: (details) {
          return details.data.entry is SpaceSidebarEntry;
        }, onAcceptWithDetails: (details) {
          print(
              "Create folder: ${(details.data.entry as SpaceSidebarEntry).space.displayName}  --> ${i.space.displayName}");

          var componentA =
              i.space.client.getComponent<SidebarEntriesComponent>()!;
          var folderId = componentA.createFolder(i.space);

          var space = (details.data.entry as SpaceSidebarEntry).space;
          var componentB =
              space.client.getComponent<SidebarEntriesComponent>()!;
          componentB.addToFolder(space, folderId);
        }, builder: (context, candidateData, rejectedData) {
          return SizedBox(
            width: widget.width,
            child: buildSpaceIcon(
              space: i.space,
              displayName: i.space.displayName,
              onUpdate: i.space.onUpdate,
              avatar: i.space.avatar,
              notificationCount: i.space.displayNotificationCount,
              highlightedNotificationCount:
                  i.space.displayHighlightedNotificationCount,
              showAvatarForSpace:
                  widget.shouldShowAvatarForSpace?.call(i.space) ?? false,
              userAvatar: i.space.client.self!.avatar,
              userColor: i.space.client.self!.defaultColor,
              userDisplayName: i.space.client.self!.displayName,
              width: widget.width,
              onSelected: widget.onSelected,
              placeholderColor: i.space.color,
            ),
          );
        }),
      );
    }

    if (data case SpaceGroupSidebarEntry i) {
      return DragTarget<SidebarEntryDrag>(
          key: ValueKey("space-group-${i.groupId}"),
          onWillAcceptWithDetails: (details) {
            Log.i("Folder will accept drag: $details");
            return details.data.entry is SpaceSidebarEntry;
          },
          onAcceptWithDetails: (details) {
            Log.i("Folder accepted drag: $details");
            var space = (details.data.entry as SpaceSidebarEntry).space;
            var component =
                space.client.getComponent<SidebarEntriesComponent>()!;
            component.addToFolder(space, i.id);
          },
          builder: (BuildContext context, List<Object?> candidateData,
              List<dynamic> rejectedData) {
            return SpaceGroupWidget(
              spaces: i.spaces,
              width: widget.width,
              folderId: i.groupId,
              onSelected: widget.onSelected,
              onDragStarted: onDragStarted,
              onDragUpdate: onDragUpdate,
              onDragEnd: onDragEnd,
            );
          });
    }

    return SizedBox(
        width: widget.width, height: widget.width, child: Placeholder());
  }

  void onDragEnd(details) {
    setState(() {
      dragPosition = null;
    });
  }

  void onDragUpdate(details) {
    details.globalPosition;
    setState(() {
      dragPosition = details.globalPosition;
    });
  }

  void onDragStarted() {
    setState(() {
      dragPosition = null;
    });
  }

  static Widget buildSpaceIcon(
      {required String displayName,
      Stream<void>? onUpdate,
      ImageProvider? avatar,
      ImageProvider? userAvatar,
      Color? userColor,
      String? userDisplayName,
      Color? placeholderColor,
      required double width,
      void Function(Space space)? onSelected,
      bool showAvatarForSpace = false,
      int highlightedNotificationCount = 0,
      int notificationCount = 0,
      required Space space}) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Padding(
            padding: SpaceSelector.padding,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: SpaceIcon(
                displayName: displayName,
                onUpdate: onUpdate,
                avatar: avatar,
                userAvatar: userAvatar,
                spaceId: space.identifier,
                userColor: userColor,
                userDisplayName: userDisplayName,
                highlightedNotificationCount: highlightedNotificationCount,
                notificationCount: notificationCount,
                width: width,
                placeholderColor: placeholderColor,
                onTap: () {
                  onSelected?.call(space);
                },
                showUser: showAvatarForSpace,
              ),
            )),
        if (notificationCount > 0) messageOverlay()
      ],
    );
  }

  static Widget messageOverlay() {
    return const Positioned(left: -6, child: DotIndicator());
  }
}
