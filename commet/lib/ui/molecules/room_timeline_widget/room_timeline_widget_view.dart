import 'dart:async';
import 'dart:ui';

import 'package:commet/client/timeline.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_overlay.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RoomTimelineWidgetView extends StatefulWidget {
  const RoomTimelineWidgetView(
      {required this.timeline,
      this.markAsRead,
      this.onViewScrolled,
      this.setEditingEvent,
      this.setReplyingEvent,
      this.onAttachedToBottom,
      this.isThreadTimeline = false,
      super.key});
  final Timeline timeline;
  final Function(TimelineEvent event)? markAsRead;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function()? onAttachedToBottom;
  final bool isThreadTimeline;

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

  GlobalKey firstFrameScrollViewKey = GlobalKey();
  GlobalKey scrollViewKey = GlobalKey();
  GlobalKey centerKey = GlobalKey();
  GlobalKey recentItemsKey = GlobalKey();
  GlobalKey overlayKey = GlobalKey();

  int highlightedEventIndex = -1;
  GlobalKey highlightedEventColumnKey = GlobalKey();
  GlobalKey columnKey = GlobalKey();
  GlobalKey columnCenterEventKey = GlobalKey();
  GlobalKey stackKey = GlobalKey();
  ScrollController columnScrollController = ScrollController();

  LayerLink selectedEventLayerLink = LayerLink();
  SelectableEventViewWidget? selectedEventView;

  TimelineViewEntryState? highlightedEventState;

  late List<StreamSubscription> subscriptions;

  bool wasLastScrollAttachedToBottom = false;

  bool get attachedToBottom => controller.hasClients
      ? controller.offset - controller.positions.first.minScrollExtent < 50
      : true;

  bool shrinkwrapOverride = false;

  bool buildColumnView = false;

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
    eventKeys.insert(index, (
      GlobalKey(debugLabel: widget.timeline.events[index].eventId),
      widget.timeline.events[index].eventId
    ));

    if (index == 0 || index < recentItemsCount) {
      recentItemsCount += 1;
    } else {
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
    }

    if (index == 0) {
      if (attachedToBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.animateTo(controller.position.minScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutExpo);
        });

        widget.markAsRead?.call(widget.timeline.events[0]);
      }
    }

    setState(() {});
  }

  void onEventChanged(int index) {
    var event = widget.timeline.events[index];
    var existing = eventKeys[index];
    eventKeys[index] = (existing.$1, event.eventId);

    var key = eventKeys.firstWhere(
      (element) => element.$2 == event.eventId,
    );

    assert(event.eventId == key.$2);

    var state = key.$1.currentState;

    if (state is TimelineEventViewWidget) {
      (state as TimelineEventViewWidget).update(index);
    } else {
      Log.w("Failed to get state");
    }
  }

  void onEventRemoved(int index) {
    if (index < recentItemsCount) {
      recentItemsCount -= 1;
    } else {
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
    }
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
      scrollViewKey = GlobalKey();
      controller.addListener(onScroll);
      widget.onAttachedToBottom?.call();
      setState(() {
        firstFrame = false;
      });
    }
  }

  void onScroll() {
    widget.onViewScrolled?.call(
        offset: controller.offset,
        maxScrollExtent: controller.position.maxScrollExtent);

    Log.d("Scroll: ${controller.offset}");

    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.setAttachedToBottom(attachedToBottom);

    if (wasLastScrollAttachedToBottom == false && attachedToBottom) {
      widget.onAttachedToBottom?.call();
    }

    wasLastScrollAttachedToBottom = attachedToBottom;
  }

  void snapToBottom() {
    controller.position.hold(() {});

    var overlayState = overlayKey.currentState as TimelineOverlayState?;

    widget.onAttachedToBottom?.call();

    WidgetsBinding.instance.addPostFrameCallback((d) {
      var columnBox = columnKey.globalPaintBounds;
      var fullHeight = columnBox!.height;

      setState(() {
        resetScrollView(-fullHeight);
        buildColumnView = false;
        overlayState?.setAttachedToBottom(attachedToBottom);
      });
    });

    setState(() {
      columnKey = GlobalKey();
      buildColumnView = true;
    });
  }

  void resetScrollView(double initialOffset) {
    controller = ScrollController(initialScrollOffset: initialOffset);
    scrollViewKey = GlobalKey();
    controller.addListener(onScroll);
  }

  void eventHovered(String eventId) {
    var key = eventKeys.firstWhere(
      (element) => element.$2 == eventId,
    );

    assert(eventId == key.$2);

    var state = key.$1.currentState;

    if (state is SelectableEventViewWidget) {
      var selectable = state as SelectableEventViewWidget;

      if (selectable != selectedEventView) {
        deselectEvent();

        selectable.select(selectedEventLayerLink);
        selectedEventView = selectable;

        var overlayState = overlayKey.currentState as TimelineOverlayState?;
        var event = widget.timeline.tryGetEvent(eventId)!;
        overlayState?.setMenu(TimelineEventMenu(
          timeline: widget.timeline,
          isThreadTimeline: widget.isThreadTimeline,
          event: event,
          setEditingEvent: (event) => widget.setEditingEvent?.call(event),
          setReplyingEvent: (event) => widget.setReplyingEvent?.call(event),
        ));
      }
    } else {
      Log.w("Failed to get selectable state");
    }
  }

  void deselectEvent() {
    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.clearSelection();

    selectedEventView?.deselect();
    selectedEventView = null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        // onExit: (_) => deselectEvent(),
        child: ClipRect(
          child: Stack(
            key: stackKey,
            children: [
              Offstage(
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
                          int timelineIndex =
                              recentItemsCount - sliverIndex - 1;
                          numBuilds += 1;

                          var key = eventKeys[timelineIndex];
                          assert(key.$2 ==
                              widget.timeline.events[timelineIndex].eventId);

                          return Container(
                            alignment: Alignment.center,
                            color:
                                preferences.developerMode && BuildConfig.DEBUG
                                    ? Colors.blue[200 + sliverIndex % 4 * 100]!
                                        .withAlpha(30)
                                    : null,
                            child: TimelineViewEntry(
                                key: key.$1,
                                timeline: widget.timeline,
                                onEventHovered: eventHovered,
                                setEditingEvent: widget.setEditingEvent,
                                setReplyingEvent: widget.setReplyingEvent,
                                isThreadTimeline: widget.isThreadTimeline,
                                jumpToEvent: jumpToEvent,
                                initialIndex: timelineIndex),
                          );
                        },
                        findChildIndexCallback: (key) {
                          var timelineIndex = eventKeys
                              .indexWhere((element) => element.$1 == key);
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
                          var timelineIndex = recentItemsCount + sliverIndex;

                          var key = eventKeys[timelineIndex];
                          assert(key.$2 ==
                              widget.timeline.events[timelineIndex].eventId);

                          return Container(
                            alignment: Alignment.center,
                            color:
                                preferences.developerMode && BuildConfig.DEBUG
                                    ? Colors.red[200 + sliverIndex % 4 * 100]!
                                        .withAlpha(30)
                                    : null,
                            child: TimelineViewEntry(
                                key: key.$1,
                                onEventHovered: eventHovered,
                                timeline: widget.timeline,
                                setEditingEvent: widget.setEditingEvent,
                                setReplyingEvent: widget.setReplyingEvent,
                                isThreadTimeline: widget.isThreadTimeline,
                                jumpToEvent: jumpToEvent,
                                initialIndex: timelineIndex),
                          );
                        },
                        findChildIndexCallback: (key) {
                          var timelineIndex = eventKeys
                              .indexWhere((element) => element.$1 == key);
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
              TimelineOverlay(
                  key: overlayKey,
                  showMessageMenu: Layout.desktop,
                  jumpToLatest: snapToBottom,
                  link: selectedEventLayerLink),
              // Second timeline renderer that is used to measure the offset of items in the actual renderer
              //if (buildColumnView)
              Offstage(
                offstage: true,
                child: SingleChildScrollView(
                  controller: columnScrollController,
                  child: Container(
                    color: Colors.red,
                    child: Column(
                      key: columnKey,
                      verticalDirection: VerticalDirection.up,
                      children: [
                        for (int i = 0; i < widget.timeline.events.length; i++)
                          TimelineViewEntry(
                              key: highlightedEventIndex == i
                                  ? highlightedEventColumnKey
                                  : (recentItemsCount + 1) == i
                                      ? columnCenterEventKey
                                      : null,
                              timeline: widget.timeline,
                              initialIndex: i)
                      ],
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

  double inverseLerp(double a, double b, double v) {
    return (v - a) / (b - a);
  }

  jumpToEvent(String eventId) {
    if (highlightedEventState?.mounted == true) {
      highlightedEventState?.setHighlighted(false);
    }

    int index =
        widget.timeline.events.indexWhere((event) => event.eventId == eventId);
    if (index == -1) {
      return;
    }

    selectedEventView?.deselect();
    columnKey = GlobalKey();
    highlightedEventColumnKey = GlobalKey();
    columnCenterEventKey = GlobalKey();

    columnScrollController = ScrollController(initialScrollOffset: 99999);

    setState(() {
      highlightedEventIndex = index;
      buildColumnView = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((d) {
      var box = highlightedEventColumnKey.globalPaintBounds;
      if (box == null) {
        return;
      }

      var columnBox = columnKey.globalPaintBounds;
      var eventWidgetAlpha =
          inverseLerp(columnBox!.top, columnBox.bottom, box.top);

      Log.d("Box alpha: $eventWidgetAlpha");

      Log.d("Event box: $box");

      var extraAmount =
          columnBox.height - columnScrollController.position.maxScrollExtent;

      var estimatedMinExtent = -1 *
          (columnBox.height - columnCenterEventKey.globalPaintBounds!.bottom);

      //controller.position.minScrollExtent;

      var estimatedMaxExtent =
          (columnBox.height + estimatedMinExtent) - extraAmount;

      var targetPos = lerpDouble(
          estimatedMinExtent, estimatedMaxExtent, 1 - eventWidgetAlpha)!;

      Log.d("Lost scroll amount = $extraAmount");

      Log.d(
          "Column scroll min extend: ${columnScrollController.position.minScrollExtent}");

      Log.d(
          "Column scroll max extend: ${columnScrollController.position.maxScrollExtent}");

      Log.d("Controller max extent: ${controller.position.maxScrollExtent}");
      Log.d("Controller min extent: ${controller.position.minScrollExtent}");
      Log.d("Target offset: $targetPos");

      Log.d("Estimated scroll bound: $estimatedMaxExtent");
      Log.d("Estimated min extent: $estimatedMinExtent");

      Log.d("Center key box: ${columnCenterEventKey.globalPaintBounds}");

      setState(() {
        buildColumnView = false;
        resetScrollView(targetPos);
      });

      WidgetsBinding.instance.addPostFrameCallback((d) {
        var key = eventKeys[index].$1;
        if (key.currentState != null) {
          var state = (key.currentState as TimelineViewEntryState);
          state.setHighlighted(true);
          highlightedEventState = state;
          onScroll();
        }
      });
    });
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
