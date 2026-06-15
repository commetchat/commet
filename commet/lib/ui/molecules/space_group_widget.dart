import 'dart:math';

import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/client/space.dart';
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
      super.key});
  final List<Space> spaces;
  final double width;
  final String folderId;

  final VoidCallback? onDragStarted;
  final DragUpdateCallback? onDragUpdate;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onDragCompleted;

  final void Function(Space space)? onSelected;
  @override
  State<SpaceGroupWidget> createState() => _SpaceGroupWidgetState();
}

class _SpaceGroupWidgetState extends State<SpaceGroupWidget> {
  bool expanded = false;

  double get shrink => 9;
  double get expandedHeight =>
      (widget.spaces.length + 1) * (widget.width - shrink) + shrink;

  double get unexpandedHeight => widget.width;

  (int, int) indexToCoordinate(int index) {
    var row = (index / 2).toInt();
    var column = index % 2;

    return (row, column);
  }

  Duration get animationDuration => Duration(milliseconds: 300);
  Curve get curve => Curves.easeInOut;
  GlobalKey key = GlobalKey();
  BorderRadiusGeometry get radius => BorderRadiusGeometry.circular(8);
  void toggleExpansion() {
    setState(() {
      expanded = !expanded;
    });
  }

  double height = 30;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        expanded = !expanded;
      }),
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
                      color: ColorScheme.of(context).surfaceContainerLow,
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
              for (int i = 0; i < widget.spaces.length; i++) buildChild(i),
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
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChild(int i) {
    var coordinates = indexToCoordinate(i);

    var size = widget.width;
    var space = widget.spaces[i];

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
            data: SidebarEntryDrag(SpaceSidebarEntry(space, order: ""), i,
                currentFolder: widget.folderId),
            feedback: SizedBox(
              width: widget.width,
              height: widget.width,
              child: SpaceSelectorState.buildSpaceIcon(
                  displayName: space.displayName,
                  width: widget.width,
                  space: space,
                  placeholderColor: space.color,
                  showAvatarForSpace: false,
                  avatar: space.avatar),
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: SpaceSelectorState.buildSpaceIcon(
                  displayName: space.displayName,
                  width: widget.width,
                  space: space,
                  placeholderColor: space.color,
                  notificationCount: space.notificationCount,
                  onUpdate: space.onUpdate,
                  highlightedNotificationCount:
                      space.highlightedNotificationCount,
                  onSelected: widget.onSelected,
                  showAvatarForSpace: false,
                  avatar: space.avatar),
            ),
          ),
        ));
  }
}
