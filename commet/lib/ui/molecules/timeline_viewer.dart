import 'dart:async';

import 'package:commet/client/split_timeline.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';

class TimelineViewer extends StatefulWidget {
  ///Child scrollable widget.
  final Timeline timeline;

  const TimelineViewer({required this.timeline, Key? key}) : super(key: key);

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer> {
  bool attachedToBottom = true;
  final ScrollController controller = ScrollController();
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
      if (!(controller.position.pixels >= controller.position.maxScrollExtent))
        forceToBottom();
    });
  }

  void prepareForDisposal() {
    print("Preparing for disposal");
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

    controller.addListener(() {
      handleScrolling();
      handleBottomAttached();
    });

    eventAdded = widget.timeline.onEventAdded.stream.listen((index) {
      setState(() {
        if (attachedToBottom || animatingToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            animateAndSnapToBottom();
          });
        }
      });
    });

    eventChanged = widget.timeline.onChange.stream.listen((index) {
      setState(() {});
    });

    eventRemoved = widget.timeline.onRemove.stream.listen((index) {
      setState(() {});
    });
  }

  void handleBottomAttached() {
    setState(() {
      attachedToBottom =
          controller.position.pixels >= controller.position.maxScrollExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
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
