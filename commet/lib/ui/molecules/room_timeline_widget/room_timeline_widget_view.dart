import 'dart:async';

import 'package:commet/client/timeline.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:flutter/material.dart';

class RoomTimelineWidgetView extends StatefulWidget {
  const RoomTimelineWidgetView(
      {required this.timeline,
      this.markAsRead,
      this.onViewScrolled,
      super.key});
  final Timeline timeline;
  final Function(TimelineEvent event)? markAsRead;
  final Function({required double offset, required double maxScrollExtent})?
      onViewScrolled;

  @override
  State<RoomTimelineWidgetView> createState() => RoomTimelineWidgetViewState();
}

class RoomTimelineWidgetViewState extends State<RoomTimelineWidgetView> {
  int numBuilds = 0;

  int recentItemsCount = 0;
  int historyItemsCount = 0;
  bool firstFrame = true;

  late ScrollController controller;
  late List<(GlobalKey, String)> eventKeys;
  bool animatingToBottom = false;

  GlobalKey firstFrameScrollViewKey = GlobalKey();
  GlobalKey scrollViewKey = GlobalKey();
  GlobalKey centerKey = GlobalKey();
  GlobalKey recentItemsKey = GlobalKey();

  late List<StreamSubscription> subscriptions;

  bool get attachedToBottom => controller.hasClients
      ? controller.offset - controller.positions.first.minScrollExtent < 50 ||
          animatingToBottom
      : true;

  @override
  void initState() {
    recentItemsCount = widget.timeline.events.length;

    subscriptions = [
      widget.timeline.onEventAdded.stream.listen(onEventAdded),
      widget.timeline.onChange.stream.listen(onEventChanged),
      widget.timeline.onRemove.stream.listen(onEventRemoved),
    ];

    controller = ScrollController(initialScrollOffset: -999999);
    WidgetsBinding.instance.addPostFrameCallback(onAfterFirstFrame);

    eventKeys = List.from(
        widget.timeline.events
            .map((e) => (GlobalKey(debugLabel: e.eventId), e.eventId)),
        growable: true);
    super.initState();
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }

    super.dispose();
  }

  void onEventAdded(int index) {
    setState(() {});

    if (index == 0 || index < recentItemsCount) {
      recentItemsCount += 1;
    } else {
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
    }

    eventKeys.insert(index, (
      GlobalKey(debugLabel: widget.timeline.events[index].eventId),
      widget.timeline.events[index].eventId
    ));

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
    Log.d("Event changed: $index");
    var event = widget.timeline.events[index];
    var existing = eventKeys[index];
    eventKeys[index] = (existing.$1, event.eventId);

    var key = eventKeys.firstWhere(
      (element) => element.$2 == event.eventId,
    );

    assert(event.eventId == key.$2);

    var state = key.$1.currentState;

    if (state is TimelineEventViewWidget) {
      (state as TimelineViewEntryState).update(index);
    } else {
      Log.w("Failed to get state");
    }
  }

  void onEventRemoved(int index) {
    var removed = eventKeys.removeAt(index);
    assert(widget.timeline.events[index].eventId == removed.$2);
  }

  void onAfterFirstFrame(_) {
    if (widget.timeline.events.isNotEmpty) {
      widget.markAsRead?.call(widget.timeline.events.first);
    }

    if (controller.hasClients) {
      double extent = controller.position.minScrollExtent;
      controller = ScrollController(initialScrollOffset: extent);
      controller.addListener(onScroll);
      setState(() {
        firstFrame = false;
      });
    }
  }

  void onScroll() {
    widget.onViewScrolled?.call(
        offset: controller.offset,
        maxScrollExtent: controller.position.maxScrollExtent);
  }

  void animateAndSnapToBottom() {
    controller.position.hold(() {});

    animatingToBottom = true;

    int lastEvent = recentItemsCount;

    controller
        .animateTo(controller.position.minScrollExtent,
            duration: const Duration(milliseconds: 5000),
            curve: Curves.easeOutExpo)
        .then((value) {
      if (recentItemsCount == lastEvent) {
        controller.jumpTo(controller.position.minScrollExtent);

        animatingToBottom = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Offstage(
        offstage: firstFrame,
        child: CustomScrollView(
          key: firstFrame ? firstFrameScrollViewKey : scrollViewKey,
          controller: controller,
          reverse: true,
          center: centerKey,
          slivers: <Widget>[
            SliverList(
              key: recentItemsKey,
              // Recent Items
              delegate: SliverChildBuilderDelegate(
                childCount: recentItemsCount,
                addAutomaticKeepAlives: false,
                (BuildContext context, int sliverIndex) {
                  int timelineIndex = recentItemsCount - sliverIndex - 1;
                  numBuilds += 1;

                  var key = eventKeys[timelineIndex];
                  assert(
                      key.$2 == widget.timeline.events[timelineIndex].eventId);

                  return Container(
                    alignment: Alignment.center,
                    color: preferences.developerMode && BuildConfig.DEBUG
                        ? Colors.blue[200 + sliverIndex % 4 * 100]!
                            .withAlpha(30)
                        : null,
                    child: TimelineViewEntry(
                        key: key.$1,
                        timeline: widget.timeline,
                        initialIndex: timelineIndex),
                  );
                },
                findChildIndexCallback: (key) {
                  var timelineIndex =
                      eventKeys.indexWhere((element) => element.$1 == key);
                  if (timelineIndex == -1) {
                    Log.w(
                        "Failed to get timeline index for key: $timelineIndex");
                    return null;
                  }

                  return recentItemsCount - timelineIndex - 1;
                },
              ),
            ),
            SliverList(
              key: centerKey,
              // History Items
              delegate: SliverChildBuilderDelegate(
                addAutomaticKeepAlives: false,
                childCount: historyItemsCount,
                (BuildContext context, int sliverIndex) {
                  numBuilds += 1;
                  // ignore: avoid_print
                  Log.d("Num Builds: $numBuilds");
                  var timelineIndex = recentItemsCount + sliverIndex;

                  var key = eventKeys[timelineIndex];
                  assert(
                      key.$2 == widget.timeline.events[timelineIndex].eventId);

                  return Container(
                    alignment: Alignment.center,
                    color: preferences.developerMode && BuildConfig.DEBUG
                        ? Colors.red[200 + sliverIndex % 4 * 100]!.withAlpha(30)
                        : null,
                    child: TimelineViewEntry(
                        key: key.$1,
                        timeline: widget.timeline,
                        initialIndex: timelineIndex),
                  );
                },
                findChildIndexCallback: (key) {
                  var timelineIndex =
                      eventKeys.indexWhere((element) => element.$1 == key);
                  if (timelineIndex == -1) {
                    Log.w(
                        "Failed to get timeline index for key: $timelineIndex");
                    return null;
                  }

                  return timelineIndex - recentItemsCount;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
