import 'dart:async';
import 'dart:math';

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

  GlobalKey newEventsListKey = GlobalKey();
  GlobalKey historyListKey = GlobalKey();

  List<TimelineEvent> history = <TimelineEvent>[];
  List<TimelineEvent> newEvents = <TimelineEvent>[];
  int newEventsCount = 0;
  int historyEventsCount = 0;
  bool toBeDisposed = false;
  bool animatingToBottom = false;
  int hoveredEvent = -1;

  int displayListIndexToTimelineIndex(int index, bool history) {
    if (history) return reverseIndexHistory(index) + newEvents.length;
    return reverseIndexNew(index);
  }

  void animateAndSnapToBottom() {
    if (toBeDisposed) {
      print("Cancelling animation about to be disposed");
      return;
    }

    controller.position.hold(() {});

    var lastEvent = newEvents[0];

    animatingToBottom = true;

    controller
        .animateTo(controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 500), curve: Curves.easeOutExpo)
        .then((value) {
      if (newEvents[0] == lastEvent) {
        controller.jumpTo(controller.position.maxScrollExtent);
        animatingToBottom = false;
      }
    });
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

  @override
  void initState() {
    super.initState();

    newEvents =
        List.from(widget.timeline.events.sublist(0, min(widget.timeline.events.length - 1, 20)), growable: true);
    newEventsCount = newEvents.length;

    controller.addListener(() {
      handleBottomAttached();
    });

    eventAdded = widget.timeline.onEventAdded.stream.listen((index) {
      newEvents.insert(index, widget.timeline.events[index]);
      setState(() {
        newEventsCount++;

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
      setState(() {
        newEventsCount--;
        newEvents.removeAt(index);
      });
    });
  }

  int reverseIndexHistory(int index) {
    return history.length - index - 1;
  }

  int reverseIndexNew(int index) {
    return newEvents.length - index - 1;
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
          return TimelineEventView(
            event: history[reverseIndexHistory(index)],
            onDelete: () {
              widget.timeline.deleteEventByIndex(reverseIndexHistory(index));
            },
          );
        }, childCount: history.length)),
        SliverList(
            key: newEventsListKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    hoveredEvent = reverseIndexNew(index);
                  });
                },
                onExit: (_) {
                  setState(() {
                    hoveredEvent = -1;
                  });
                },
                child: TimelineEventView(
                  showSender: shouldShowSender(reverseIndexNew(index)),
                  event: newEvents[reverseIndexNew(index)],
                  onDelete: () {
                    widget.timeline.deleteEventByIndex(displayListIndexToTimelineIndex(index, false));
                  },
                ),
              );
            }, childCount: newEventsCount)),
      ],
    );
  }

  bool shouldShowSender(int index) {
    if (widget.timeline.events.length < index + 1) {
      return true;
    }

    if (widget.timeline.events[index].originServerTs
            .difference(widget.timeline.events[index + 1].originServerTs)
            .inMinutes >
        1) return true;

    return widget.timeline.events[index].sender != widget.timeline.events[index + 1].sender;
  }
}
