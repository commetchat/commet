import 'dart:async';

import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/client/space.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/ui/molecules/expanding_drop_target.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceGroupWidget extends StatefulWidget {
  const SpaceGroupWidget(
      {required this.spaces,
      this.onSelected,
      required this.folderId,
      this.width = 44,
      this.onDragEnd,
      this.onDragCompleted,
      this.onDragStarted,
      this.onDragUpdate,
      this.dragPosition,
      this.initiallyOpen = false,
      this.onExpansionStateChanged,
      this.shouldShowAvatarForSpace,
      super.key});
  final List<SpaceSidebarEntry> spaces;
  final double width;
  final String folderId;
  final bool initiallyOpen;
  final Offset? dragPosition;
  final VoidCallback? onDragStarted;
  final DragUpdateCallback? onDragUpdate;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onDragCompleted;
  final void Function(bool expanded)? onExpansionStateChanged;
  final bool Function(Space space)? shouldShowAvatarForSpace;

  final void Function(Space space)? onSelected;
  @override
  State<SpaceGroupWidget> createState() => _SpaceGroupWidgetState();
}

class _SpaceGroupWidgetState extends State<SpaceGroupWidget> {
  late bool expanded;

  double get shrink => 9;

  double get dragDropAreaSize => 40;

  double get expandedHeight =>
      (widget.spaces.length + 1) * (widget.width - shrink) +
      shrink +
      (dragPosition == null ? 0 : widget.spaces.length * dragDropAreaSize);

  double get unexpandedHeight => widget.width;

  Offset? dragPosition;

  late List<SpaceSidebarEntry> entries;

  (int, int) indexToCoordinate(int index) {
    var row = (index / 2).toInt();
    var column = index % 2;

    return (row, column);
  }

  int notificationCount = 0;
  int highlightNotificationCount = 0;

  void updateNotificationCounts() {
    notificationCount = 0;
    highlightNotificationCount = 0;

    for (var entry in entries) {
      notificationCount += entry.space.notificationCount;
      highlightNotificationCount += entry.space.highlightedNotificationCount;
    }
  }

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyOpen;

    sub = clientManager?.onSpaceUpdated.stream.listen(onSpaceUpdated);

    updateEntries();
  }

  void onSpaceUpdated(Space event) {
    setState(() {
      updateNotificationCounts();
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void updateEntries() {
    print("Updating group entries");
    entries = widget.spaces.toList();
    entries.sort((a, b) => a.order.compareTo(b.order));

    dragPosition = widget.dragPosition;

    setState(() {
      updateNotificationCounts();
    });
  }

  @override
  void didUpdateWidget(covariant SpaceGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    setState(() {
      dragPosition = widget.dragPosition;
      updateEntries();
    });
  }

  Duration get animationDuration => Duration(milliseconds: 300);
  Curve get curve => Curves.easeInOut;
  GlobalKey key = GlobalKey();

  BorderRadiusGeometry get radius => BorderRadiusGeometry.circular(12);

  void toggleExpansion() {
    setState(() {
      expanded = !expanded;
    });

    widget.onExpansionStateChanged?.call(expanded);
  }

  double height = 30;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleExpansion,
      child: AnimatedContainer(
        key: key,
        alignment: AlignmentGeometry.topLeft,
        decoration: BoxDecoration(borderRadius: radius),
        height: expanded ? expandedHeight : unexpandedHeight,
        clipBehavior: Clip.hardEdge,
        duration: animationDuration,
        curve: curve,
        child: SizedBox(
          width: widget.width,
          height: expandedHeight,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  alignment: AlignmentGeometry.topLeft,
                  decoration: BoxDecoration(
                      color: ColorScheme.of(context).surfaceContainerHigh,
                      borderRadius: radius),
                  height: expanded ? expandedHeight : unexpandedHeight,
                  clipBehavior: Clip.hardEdge,
                  duration: animationDuration,
                  curve: curve,
                  child: AnimatedOpacity(
                    opacity: expanded ? 1.0 : 0,
                    duration: animationDuration,
                    child: ClipRRect(
                        borderRadius: radius,
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: toggleExpansion,
                            child: SizedBox(
                              width: widget.width,
                              height: widget.width - shrink,
                              child: Icon(Icons.folder),
                            ),
                          ),
                        )),
                  ),
                ),
              ),
              for (int i = 0; i < entries.length; i++) buildChild(i),
              if (expanded == false)
                LongPressDraggable<SidebarEntryDrag>(
                  data: SidebarEntryDrag(SidebarEntry(widget.folderId, ""), 0),
                  onDragCompleted: widget.onDragCompleted,
                  onDragEnd: widget.onDragEnd,
                  onDragUpdate: widget.onDragUpdate,
                  onDragStarted: widget.onDragStarted,
                  feedback: SizedBox(
                    width: widget.width,
                    height: widget.width - shrink,
                    child: Icon(Icons.folder),
                  ),
                  child: MouseRegion(
                    onEnter: (event) {},
                    onExit: (event) {},
                    child: GestureDetector(
                      onTap: toggleExpansion,
                      child: Opacity(
                        opacity: 0,
                        child: SizedBox(
                          width: widget.width,
                          height: widget.width,
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: AnimatedScale(
                      scale: (expanded || highlightNotificationCount == 0)
                          ? 0.0
                          : 1.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutExpo,
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: NotificationBadge(highlightNotificationCount)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChild(int i) {
    var coordinates = indexToCoordinate(i);

    var size = widget.width;
    var space = entries[i];

    var scale = 0.4;
    var left = (coordinates.$2 * size / 2) - (size / 4);
    var top = coordinates.$1 * size / 2 - (size / 4);

    double sidePadding = 3;
    if (coordinates.$2 == 0) {
      left += sidePadding;
    } else {
      left -= sidePadding;
    }

    if (coordinates.$1 == 0) {
      top += sidePadding;
    } else {
      top -= sidePadding;
    }

    if (expanded) {
      size = widget.width;
      left = 0;
      scale = 0.999;
      top = (i + 1) * (size - shrink);
      if (dragPosition != null) {
        top += dragDropAreaSize * i;
      }
    }

    return AnimatedPositioned(
        duration: animationDuration,
        curve: curve,
        top: top,
        left: left,
        child: AnimatedScale(
          scale: scale,
          alignment: Alignment.center,
          duration: animationDuration,
          curve: curve,
          child: LongPressDraggable<SidebarEntryDrag>(
            onDragCompleted: widget.onDragCompleted,
            onDragEnd: widget.onDragEnd,
            onDragUpdate: widget.onDragUpdate,
            onDragStarted: widget.onDragStarted,
            data: SidebarEntryDrag(space, i, currentFolder: widget.folderId),
            feedback: Opacity(
              opacity: 0.5,
              child: SizedBox(
                width: widget.width,
                height: widget.width,
                child: SpaceSelectorState.buildSpaceIcon(
                    displayName: space.space.displayName,
                    width: widget.width,
                    space: space.space,
                    placeholderColor: space.space.color,
                    showAvatarForSpace: false,
                    avatar: space.space.avatar),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.2,
              child: SizedBox(
                width: widget.width,
                height: widget.width,
                child: SpaceSelectorState.buildSpaceIcon(
                    displayName: space.space.displayName,
                    width: widget.width,
                    space: space.space,
                    placeholderColor: space.space.color,
                    showAvatarForSpace: false,
                    avatar: space.space.avatar),
              ),
            ),
            child: Column(
              children: [
                if (dragPosition != null && expanded)
                  SizedBox(
                    height: dragDropAreaSize,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: ExpandingDropTarget<SidebarEntryDrag>(
                        height: dragDropAreaSize,
                        distanceBasedHeight: false,
                        onWillAcceptWithDetails: (p0) {
                          if (p0 case SidebarEntryDrag data) {
                            return data.entry is SpaceSidebarEntry;
                          }

                          return false;
                        },
                        onAcceptWithDetails: (p0) {
                          if (p0 is DragTargetDetails) {
                            if (p0.data case SidebarEntryDrag data) {
                              if (data.entry case SpaceSidebarEntry space) {
                                var component = space.space.client
                                    .getComponent<SidebarEntriesComponent>();

                                int index = adjustIndex(i, space.space.localId);

                                print(
                                    "Adding ${space.space.displayName} to folder at index: $i");
                                component!.addToFolder(
                                    space.space, widget.folderId, index);
                              }
                            }
                          }

                          //handleSpaceOrderDropped(p0, index);
                        },
                        position: dragPosition,
                      ),
                    ),
                  ),
                tiamat.Tooltip(
                  text: space.space.displayName,
                  preferredDirection: AxisDirection.right,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: SpaceSelectorState.buildSpaceIcon(
                        displayName: space.space.displayName,
                        width: widget.width,
                        space: space.space,
                        placeholderColor: space.space.color,
                        notificationCount: space.space.notificationCount,
                        onUpdate: space.space.onUpdate,
                        highlightedNotificationCount:
                            space.space.highlightedNotificationCount,
                        onSelected: widget.onSelected,
                        userAvatar: space.space.client.self?.avatar,
                        userColor: space.space.client.self?.defaultColor,
                        userDisplayName: space.space.client.self?.displayName,
                        showAvatarForSpace: widget.shouldShowAvatarForSpace
                                ?.call(space.space) ??
                            false,
                        avatar: space.space.avatar),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  int adjustIndex(int targetIndex, String id) {
    int currentIndex = entries.indexWhere(
      (element) => element.id == id,
    );

    if (currentIndex == -1) return targetIndex;

    if (targetIndex > currentIndex) {
      return targetIndex - 1;
    }

    return targetIndex;
  }
}
