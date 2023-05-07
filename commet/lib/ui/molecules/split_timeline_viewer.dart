import 'dart:async';

import 'package:commet/client/split_timeline.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';
/*
 This contains a weird hack to bring the scroll view down to the bottom
 On the first frame we render offstage, with an initial scroll offset of 999999
 Then on the next frame we can measure the max scroll extent, create a new scroll controller which
 initializes at that max scroll extent, then we actually render on stage the following frame
*/

class SplitTimelineViewer extends StatefulWidget {
  final Timeline timeline;

  const SplitTimelineViewer({required this.timeline, this.markAsRead, Key? key})
      : super(key: key);

  final Function(TimelineEvent event)? markAsRead;

  @override
  State<SplitTimelineViewer> createState() => SplitTimelineViewerState();
}

class SplitTimelineViewerState extends State<SplitTimelineViewer> {
  bool attachedToBottom = true;
  ScrollController controller = ScrollController(initialScrollOffset: 999999);

  bool firstFrame = true;
  final ScrollPhysics physics = const BouncingScrollPhysics();
  late StreamSubscription eventAdded;
  late StreamSubscription eventChanged;
  late StreamSubscription eventRemoved;

  late SplitTimeline split;

  GlobalKey newEventsListKey = GlobalKey();
  GlobalKey historyListKey = GlobalKey();
  bool toBeDisposed = false;
  bool animatingToBottom = false;
  int hoveredEvent = -1;

  void animateAndSnapToBottom() {
    if (toBeDisposed) return;
    controller.position.hold(() {});

    TimelineEvent? lastEvent = split.recent.isNotEmpty ? split.recent[0] : null;

    animatingToBottom = true;

    controller
        .animateTo(controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutExpo)
        .then((value) {
      TimelineEvent? latest = split.recent.isNotEmpty ? split.recent[0] : null;
      if (latest == lastEvent) {
        controller.jumpTo(controller.position.maxScrollExtent);
        animatingToBottom = false;
      }
    });
  }

  bool historyLoading = false;
  void loadMore() async {
    if (historyLoading) return;
    if (!split.isMoreHistoryAvailable()) {
      historyLoading = true;
      await widget.timeline.loadMoreHistory();
      historyLoading = false;
    } else {
      split.loadMoreHistory();
    }

    setState(() {});
  }

  void forceToBottom() {
    controller.jumpTo(controller.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!(controller.position.pixels >=
          controller.position.maxScrollExtent)) {
        forceToBottom();
      }
    });
  }

  void prepareForDisposal() {
    toBeDisposed = true;
    controller.position.hold(() {});
  }

  @override
  void dispose() {
    eventAdded.cancel();
    super.dispose();
  }

  void handleScrolling() {
    if (controller.offset < controller.position.minScrollExtent + 200) {
      loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    split = SplitTimeline(widget.timeline, chunkSize: 50);
    if (widget.timeline.events.length < 50) loadMore();

    eventAdded = widget.timeline.onEventAdded.stream.listen((index) {
      setState(() {
        if (attachedToBottom || animatingToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            animateAndSnapToBottom();
          });
          widget.markAsRead?.call(widget.timeline.events.first);
        }
      });
    });

    eventChanged = widget.timeline.onChange.stream.listen((index) {
      setState(() {});
    });

    eventRemoved = widget.timeline.onRemove.stream.listen((index) {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        double extent = controller.position.maxScrollExtent;
        controller = ScrollController(initialScrollOffset: extent);
        controller.addListener(() {
          handleScrolling();
          handleBottomAttached();
        });
        setState(() {
          firstFrame = false;
          widget.markAsRead?.call(widget.timeline.events.first);
        });
      },
    );
  }

  void handleBottomAttached() {
    setState(() {
      attachedToBottom = controller.position.pixels >=
          controller.position.maxScrollExtent - 20;

      if (attachedToBottom) {
        widget.markAsRead?.call(widget.timeline.events.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (firstFrame) {
      return Offstage(child: buildListView());
    }
    return buildListView();
  }

  CustomScrollView buildListView() {
    return CustomScrollView(
      center: newEventsListKey,
      controller: controller,
      physics: physics,
      slivers: <Widget>[
        SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
          int actualIndex = split.getTimelineIndex(
              split.getHistoryDisplayIndex(index),
              SplitTimelinePart.historical);

          return TimelineEventView(
            event: split.historical[split.getHistoryDisplayIndex(index)],
            showSender: shouldShowSender(split.getTimelineIndex(
                split.getHistoryDisplayIndex(index),
                SplitTimelinePart.historical)),
            debugInfo:
                "Split Part: ${split.whichList(actualIndex)} history index: $index, actual index: $actualIndex, actual index id: ${widget.timeline.events[actualIndex].eventId}",
            onDelete: () {
              widget.timeline.deleteEventByIndex(index);
            },
          );
        }, childCount: split.historical.length)),
        SliverList(
            key: newEventsListKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              int actualIndex = split.getTimelineIndex(
                  split.getRecentDisplayIndex(index), SplitTimelinePart.recent);
              return TimelineEventView(
                showSender: shouldShowSender(split.getTimelineIndex(
                    split.getRecentDisplayIndex(index),
                    SplitTimelinePart.recent)),
                event: split.recent[split.getRecentDisplayIndex(index)],
                debugInfo:
                    "Split Part: ${split.whichList(actualIndex)} history index: $index, actual index: $actualIndex, actual index id: ${widget.timeline.events[actualIndex].eventId}",
                onDelete: () {
                  widget.timeline.deleteEventByIndex(
                      split.getTimelineIndex(index, SplitTimelinePart.recent));
                },
              );
            }, childCount: split.recent.length)),
      ],
    );
  }

  bool shouldShowSender(int index) {
    if (widget.timeline.events.length <= index + 1) {
      return true;
    }

    if (widget.timeline.events[index].originServerTs
            .difference(widget.timeline.events[index + 1].originServerTs)
            .inMinutes >
        1) return true;

    return widget.timeline.events[index].sender !=
        widget.timeline.events[index + 1].sender;
  }
}
