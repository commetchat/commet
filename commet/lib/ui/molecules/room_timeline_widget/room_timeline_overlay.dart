import 'package:commet/main.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_overlay_button.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:tiamat/atoms/context_menu.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:flutter/material.dart' as m;

class TimelineOverlay extends StatefulWidget {
  const TimelineOverlay(
      {required this.link,
      this.showMessageMenu = true,
      this.jumpToLatest,
      super.key});
  final LayerLink link;
  final bool showMessageMenu;
  final Function()? jumpToLatest;

  @override
  State<TimelineOverlay> createState() => TimelineOverlayState();
}

class TimelineOverlayState extends State<TimelineOverlay> {
  TimelineEventMenu? currentMenu;
  JustTheController controller = JustTheController();
  PageStorageBucket storage = PageStorageBucket();

  TimelineEventMenuEntry? selectedEntry;
  GlobalKey menuKey = GlobalKey();

  bool? openDownwards;

  final double tooltipHeight = 300;

  bool isAttatchedToBottom = true;

  String get labelJumpToLatest => Intl.message("Jump to latest",
      desc:
          "Label for the button which jumps the room timeline view to the latest message",
      name: "labelJumpToLatest");

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showMessageMenu)
          Positioned(
              right: 0,
              top: 0,
              child: CompositedTransformFollower(
                  targetAnchor: Alignment.topRight,
                  followerAnchor: openDownwards == true
                      ? Alignment.topRight
                      : Alignment.bottomRight,
                  showWhenUnlinked: false,
                  offset: Offset(-20, openDownwards == true ? -50 : 0),
                  link: widget.link,
                  child: MouseRegion(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: buildTooltipMenu(child: buildPrimaryMenu(context)),
                  )))),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            offset: Offset(0, !isAttatchedToBottom ? 0 : 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: RoomTimelineOverlayButton(
              text: labelJumpToLatest,
              onTap: widget.jumpToLatest,
            ),
          ),
        )
      ],
    );
  }

  Widget buildTooltipMenu({required Widget child}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        verticalDirection: openDownwards == true
            ? VerticalDirection.up
            : VerticalDirection.down,
        children: [
          if (selectedEntry != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Tile.surfaceContainer(
                  child: SizedBox(
                      width: tooltipHeight,
                      height: tooltipHeight,
                      child: MouseRegion(
                          child: selectedEntry!.secondaryMenuBuilder
                              ?.call(context, clearSelection))),
                ),
              ),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }

  Widget buildPrimaryMenu(BuildContext context) {
    var reactions = currentMenu?.recentReactions;
    if (reactions != null) {
      if (reactions.length > 4) {
        reactions = reactions.sublist(0, 4);
      }
    }
    const double size = 30;

    return MouseRegion(
      child: DecoratedBox(
          key: menuKey,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: m.Theme.of(context).colorScheme.surfaceDim,
              border: Border.all(
                  color:
                      m.Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 1)),
          child: currentMenu != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Row(children: [
                    for (var e in reactions!)
                      buildAction(
                          name: e.shortcode,
                          child: EmojiWidget(
                            e,
                            height: size / 1.5,
                            padding: const EdgeInsetsGeometry.all(2),
                          ),
                          onTap: () {
                            currentMenu?.timeline.room
                                .addReaction(currentMenu!.event, e);
                          }),
                    if (currentMenu!.addReactionAction != null)
                      buildAction(
                          name: currentMenu!.addReactionAction!.name,
                          child: m.Icon(
                            currentMenu!.addReactionAction!.icon,
                            color: Theme.of(context).colorScheme.secondary,
                            size: size / 1.5,
                          ),
                          onTap: () =>
                              togglePopupMenu(currentMenu!.addReactionAction!)),
                    if (currentMenu!.addReactionAction != null)
                      SizedBox(height: 10, child: VerticalDivider()),
                    for (var e in currentMenu!.primaryActions)
                      buildAction(
                          name: e.name,
                          child: m.Icon(
                            e.icon,
                            color: Theme.of(context).colorScheme.secondary,
                            size: size / 1.5,
                          ),
                          size: size,
                          onTap: e.secondaryMenuBuilder != null
                              ? () => togglePopupMenu(e)
                              : () => e.action?.call(context)),
                    buildAction(
                        name: "Options",
                        child: Icon(m.Icons.more_vert),
                        size: size,
                        contextMenuItems: currentMenu!.secondaryActions
                            .map((e) => ContextMenuItem(
                                text: e.name,
                                icon: e.icon,
                                onPressed: () => e.action?.call(context)))
                            .toList())
                  ]),
                )
              : Container()),
    );
  }

  void clearSelection() {
    setState(() {
      openDownwards = null;
      selectedEntry = null;
    });
  }

  void togglePopupMenu(TimelineEventMenuEntry entry) {
    if (selectedEntry == entry) {
      setState(() {
        selectedEntry = null;
      });
    } else {
      var obj = menuKey.currentContext?.findRenderObject() as RenderBox;
      var pos = obj.localToGlobal(Offset.zero) * preferences.appScale;
      openDownwards = pos.dy < (tooltipHeight + 100);
      setState(() {
        selectedEntry = entry;
      });
    }
  }

  void setMenu(TimelineEventMenu menu) {
    setState(() {
      currentMenu = menu;
      selectedEntry = null;
    });
  }

  void setAttachedToBottom(bool value) {
    if (value != isAttatchedToBottom) {
      setState(() {
        isAttatchedToBottom = value;
      });
    }
  }

  Widget buildAction(
      {required Widget child,
      String? name,
      Function()? onTap,
      double size = 30,
      List<ContextMenuItem>? contextMenuItems}) {
    var pad = const EdgeInsets.all(2);

    var result = m.Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Material(
          color: Colors.transparent,
          child: m.SizedBox(
            width: size,
            height: size,
            child: contextMenuItems != null
                ? ContextMenu(
                    modal: true,
                    items: contextMenuItems,
                    child: Padding(
                      padding: pad,
                      child: child,
                    ),
                  )
                : InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: pad,
                      child: child,
                    )),
          ),
        ),
      ),
    );
    if (name != null) return tiamat.Tooltip(text: name, child: result);

    return result;
  }
}
