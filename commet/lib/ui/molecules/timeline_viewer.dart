import 'dart:async';
import 'dart:math';

import 'package:commet/client/split_timeline.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/atoms/background.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class TimelineViewer extends StatefulWidget {
  ///Child scrollable widget.
  final Timeline timeline;

  TimelineViewer({required this.timeline, Key? key}) : super(key: key);

  @override
  State<TimelineViewer> createState() => TimelineViewerState();
}

class TimelineViewerState extends State<TimelineViewer> {
  bool attachedToBottom = true;
  final ScrollController controller = ScrollController();
  final ScrollPhysics physics = BouncingScrollPhysics();
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
    if (toBeDisposed) {
      print("Cancelling animation about to be disposed");
      return;
    }

    controller.position.hold(() {});

    var lastEvent = split.recent[0];

    animatingToBottom = true;

    controller
        .animateTo(controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 500), curve: Curves.easeOutExpo)
        .then((value) {
      if (split.recent[0] == lastEvent) {
        controller.jumpTo(controller.position.maxScrollExtent);
        animatingToBottom = false;
      }
    });
  }

  bool historyLoading = false;
  void loadMore() async {
    if (historyLoading) return;
    print("LOADING MORE");

    if (!split.isMoreHistoryAvailable()) {
      print("asking timeline to load more history");
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
      if (!(controller.position.pixels >= controller.position.maxScrollExtent)) forceToBottom();
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
    print(controller.offset - controller.position.minScrollExtent);
    if (controller.offset < controller.position.minScrollExtent + 200) {
      loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    split = SplitTimeline(widget.timeline, chunkSize: 15);
    print("Split Timeline:");
    print(split.recent.length);
    print(split.historical.length);

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
      attachedToBottom = controller.position.pixels >= controller.position.maxScrollExtent;
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
          int actualIndex = split.getTimelineIndex(split.getHistoryDisplayIndex(index), SplitTimelinePart.Historical);

          return TimelineEventView(
            event: split.historical[split.getHistoryDisplayIndex(index)],
            debugInfo:
                "Split Part: ${split.whichList(actualIndex)} history index: ${index}, actual index: ${actualIndex}, actual index id: ${widget.timeline.events[actualIndex].eventId}",
            onDelete: () {
              widget.timeline.deleteEventByIndex(index);
            },
          );
        }, childCount: split.historical.length)),
        SliverList(
            key: newEventsListKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              int actualIndex = split.getTimelineIndex(split.getRecentDisplayIndex(index), SplitTimelinePart.Recent);
              return TimelineEventView(
                event: split.recent[split.getRecentDisplayIndex(index)],
                debugInfo:
                    "Split Part: ${split.whichList(actualIndex)} history index: ${index}, actual index: ${actualIndex}, actual index id: ${widget.timeline.events[actualIndex].eventId}",
                onDelete: () {
                  widget.timeline.deleteEventByIndex(split.getTimelineIndex(index, SplitTimelinePart.Recent));
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

    return widget.timeline.events[index].sender != widget.timeline.events[index + 1].sender;
  }
}
