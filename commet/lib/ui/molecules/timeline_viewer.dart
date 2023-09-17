import 'dart:async';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/message_popup_menu.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';
import '../../client/client.dart';
import '../../client/components/emoticon/emoticon.dart';

/* Note: This aint your mother's timeline viewer...
This file contains some unusual hacks in order to achieve a smoother experience

Hack #1: Split Timeline
This timeline renders elements as part of two seperate slivers
one for new events, and one for previous events
this allows us to center the scroll view on the 'middle' of the two slivers/
This prevents the view from jumping around when new items are added / removed from
the top and bottom of the timeline

---

Hack #2: First frame offscreen render
Due to the previous hack, when we initially open the viewer, the recent events are offscreen
because the scrollviewer starts with an offset of 0, and all our recent events are in an offset < 0
To work around this, on the first frame we render the scroll view offstage, so we can grab the 
minScrollExtent of the scroll view

Then after this frame is rendered, we construct a new scroll controller and set the initial offset
to the minScrollExtent we just grabbed, which places timeline right where we would expect it!

---

I know its weird but its necessary!
*/

class TimelineViewer extends StatefulWidget {
  const TimelineViewer(
      {required this.timeline,
      this.markAsRead,
      this.setReplyingEvent,
      this.onEventDoubleTap,
      this.setEditingEvent,
      this.onEventLongPress,
      this.onAddReaction,
      this.onReactionTapped,
      this.doMessageOverlayMenu = true,
      Key? key})
      : super(key: key);

  final bool doMessageOverlayMenu;
  final Timeline timeline;
  final Function(TimelineEvent event)? markAsRead;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(TimelineEvent event)? onEventDoubleTap;
  final Function(TimelineEvent event)? onEventLongPress;
  final Function(TimelineEvent event, Emoticon emote)? onAddReaction;
  final Function(TimelineEvent event, Emoticon emote)? onReactionTapped;

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer> {
  Key historyEventsKey = GlobalKey();
  ScrollController controller = ScrollController(initialScrollOffset: -999999);
  bool firstFrame = true;

  int recentItemsCount = 0;
  int historyItemsCount = 0;
  int hoveredIndex = -1;

  bool animatingToBottom = false;
  bool get attachedToBottom =>
      controller.offset - controller.positions.first.minScrollExtent < 50 ||
      animatingToBottom;

  Future? loadingHistory;
  bool toBeDisposed = false;

  StreamController<int> onHoveredMessageChanged = StreamController.broadcast();

  late StreamSubscription eventAdded;
  late StreamSubscription eventChanged;
  late StreamSubscription eventRemoved;
  final LayerLink messageLayerLink = LayerLink();
  OverlayEntry? messageOverlay;

  @override
  void initState() {
    recentItemsCount = widget.timeline.events.length;
    eventAdded = widget.timeline.onEventAdded.stream.listen(onEventAdded);
    eventChanged = widget.timeline.onChange.stream.listen(onEventChanged);
    eventRemoved = widget.timeline.onRemove.stream.listen(onEventRemoved);
    WidgetsBinding.instance.addPostFrameCallback(onAfterFirstFrame);
    super.initState();
  }

  @override
  void dispose() {
    eventAdded.cancel();
    eventChanged.cancel();
    eventRemoved.cancel();
    super.dispose();
  }

  void createOverlay() {
    if (!widget.doMessageOverlayMenu) return;

    var overlay = Overlay.of(context);
    messageOverlay = OverlayEntry(
      builder: (context) {
        return buildOverlay();
      },
    );

    overlay.insert(messageOverlay!);
  }

  Widget buildOverlay() {
    var event = widget.timeline.events[hoveredIndex];
    return Positioned(
        height: 50,
        child: CompositedTransformFollower(
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topRight,
            showWhenUnlinked: false,
            offset: const Offset(-20, -40),
            link: messageLayerLink,
            child: MessagePopupMenu(
              event,
              widget.timeline,
              isEditable: canUserEditEvent(event),
              isDeletable: widget.timeline.canDeleteEvent(event),
              deleteEvent: (event) => widget.timeline.deleteEvent(event),
              onMessageChanged: onHoveredMessageChanged.stream,
              addReaction: widget.onAddReaction,
            )));
  }

  bool canUserEditEvent(TimelineEvent event) {
    return widget.timeline.room.permissions.canUserEditMessages &&
        event.senderId == widget.timeline.room.client.self!.identifier;
  }

  void onAfterFirstFrame(_) {
    double extent = controller.position.minScrollExtent;
    controller = ScrollController(initialScrollOffset: extent);
    controller.addListener(onScroll);
    setState(() {
      firstFrame = false;
      widget.markAsRead?.call(widget.timeline.events.first);
    });
  }

  void loadMoreHistory() async {
    loadingHistory = widget.timeline.loadMoreHistory();
    await loadingHistory;
    loadingHistory = null;
  }

  bool shouldScrollPositionLoadHistory() {
    return controller.offset > controller.position.maxScrollExtent - 500;
  }

  void onScroll() {
    if (shouldScrollPositionLoadHistory()) {
      if (loadingHistory == null) loadMoreHistory();
    }
  }

  void animateAndSnapToBottom() {
    if (toBeDisposed) return;
    controller.position.hold(() {});

    animatingToBottom = true;
    int lastEvent = recentItemsCount;

    controller
        .animateTo(controller.position.minScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutExpo)
        .then((value) {
      if (recentItemsCount == lastEvent) {
        controller.jumpTo(controller.position.minScrollExtent);
        animatingToBottom = false;
      }
    });
  }

  void onEventAdded(int index) {
    setState(() {});
    if (index == 0 || index < recentItemsCount) {
      recentItemsCount += 1;
    } else {
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
    }

    if (index == 0) {
      if (attachedToBottom || animatingToBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          animateAndSnapToBottom();
        });

        widget.markAsRead?.call(widget.timeline.events[0]);
      }
    }
  }

  void onEventChanged(int index) {
    setState(() {});
  }

  void onEventRemoved(int index) {
    setState(() {});
  }

  void prepareForDisposal() {
    toBeDisposed = true;
    controller.position.hold(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (firstFrame) {
      return Offstage(
        child: buildScrollView(),
      );
    }
    return buildScrollView();
  }

  Widget buildScrollView() {
    return CustomScrollView(
      center: historyEventsKey,
      reverse: true,
      controller: controller,
      anchor: 0,
      slivers: [
        //Beware, these are in reverse order
        SliverList(
            delegate: SliverChildBuilderDelegate(buildRecentItem,
                childCount: recentItemsCount)),
        SliverList(
            key: historyEventsKey,
            delegate: SliverChildBuilderDelegate(buildHistoryItem,
                childCount: historyItemsCount)),
      ],
    );
  }

  Widget? buildHistoryItem(BuildContext context, int index) {
    var displayIndex = recentItemsCount + index;
    return Container(
        color: BuildConfig.DEBUG ? Colors.red.withAlpha(15) : null,
        child: buildEvent(displayIndex, index));
  }

  Widget? buildRecentItem(BuildContext context, int index) {
    int displayIndex = recentItemsCount - index - 1;
    return Container(
        color: BuildConfig.DEBUG ? Colors.blue.withAlpha(15) : null,
        child: buildEvent(displayIndex, index));
  }

  Widget buildEvent(int displayIndex, int actualIndex) {
    if (displayIndex == hoveredIndex) {
      return CompositedTransformTarget(
        link: messageLayerLink,
        child: buildTimelineEvent(displayIndex),
      );
    }

    return buildTimelineEvent(displayIndex);
  }

  Widget buildTimelineEvent(int index) {
    return MouseRegion(
      onEnter: (event) {
        if (index == hoveredIndex) return;

        setState(() {
          hoveredIndex = index;

          if (!widget.doMessageOverlayMenu) return;

          messageOverlay?.markNeedsBuild();
          onHoveredMessageChanged.add(index);
          if (messageOverlay == null) {
            createOverlay();
          }
        });
      },
      child: Container(
        color: hoveredIndex == index
            ? Theme.of(context).hoverColor
            : Colors.transparent,
        child: TimelineEventView(
          event: widget.timeline.events[index],
          timeline: widget.timeline,
          onReactionTapped: (emote) => widget.onReactionTapped
              ?.call(widget.timeline.events[index], emote),
          showSender: shouldShowSender(index),
          setEditingEvent: () =>
              widget.setEditingEvent?.call(widget.timeline.events[index]),
          setReplyingEvent: () =>
              widget.setReplyingEvent?.call(widget.timeline.events[index]),
          onLongPress: () =>
              widget.onEventLongPress?.call(widget.timeline.events[index]),
        ),
      ),
    );
  }

  bool shouldShowSender(int index) {
    if (widget.timeline.events.length <= index + 1) {
      return true;
    }

    if (widget.timeline.events[index].relationshipType ==
        EventRelationshipType.reply) return true;

    if (widget.timeline.events[index + 1].type != EventType.message)
      return true;

    if (widget.timeline.events[index].originServerTs
            .difference(widget.timeline.events[index + 1].originServerTs)
            .inMinutes >
        1) return true;

    return widget.timeline.events[index].senderId !=
        widget.timeline.events[index + 1].senderId;
  }
}
