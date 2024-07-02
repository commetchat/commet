import 'dart:async';

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
  bool animatingToBottom = false;

  late ScrollController controller;
  late List<(GlobalKey, String)> eventKeys;

  GlobalKey firstFrameScrollViewKey = GlobalKey();
  GlobalKey scrollViewKey = GlobalKey();
  GlobalKey centerKey = GlobalKey();
  GlobalKey recentItemsKey = GlobalKey();
  GlobalKey overlayKey = GlobalKey();
  GlobalKey stackKey = GlobalKey();

  LayerLink selectedEventLayerLink = LayerLink();
  SelectableEventViewWidget? selectedEventView;

  String? highlightedEventId;
  TimelineViewEntryState? highlightedEventState;
  GlobalKey? highlightedEventOffstageKey;
  int? highlightedEventOffstageIndex;
  late List<StreamSubscription> subscriptions;

  bool wasLastScrollAttachedToBottom = false;

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

    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.setAttachedToBottom(attachedToBottom);

    if (wasLastScrollAttachedToBottom == false && attachedToBottom) {
      widget.onAttachedToBottom?.call();
    }

    wasLastScrollAttachedToBottom = attachedToBottom;
  }

  void animateAndSnapToBottom() {
    controller.position.hold(() {});

    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.setAttachedToBottom(attachedToBottom);
    widget.onAttachedToBottom?.call();

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
                                highlightedEventId: highlightedEventId,
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
                                highlightedEventId: highlightedEventId,
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
                  jumpToLatest: animateAndSnapToBottom,
                  link: selectedEventLayerLink),
              if (highlightedEventOffstageIndex != null &&
                  highlightedEventOffstageKey != null)
                Offstage(
                  offstage: true,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.red,
                        child: TimelineViewEntry(
                          key: highlightedEventOffstageKey,
                          timeline: widget.timeline,
                          isThreadTimeline: widget.isThreadTimeline,
                          initialIndex: highlightedEventOffstageIndex!,
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void jumpToEvent(String eventId) {
    int index =
        widget.timeline.events.indexWhere((event) => event.eventId == eventId);
    if (index == -1) {
      return;
    }

    if (highlightedEventState?.mounted == true) {
      highlightedEventState!.setHighlighted(false);
      highlightedEventState = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var key = eventKeys[index].$1;
      final state = key.currentState;

      if (state is TimelineViewEntryState) {
        state.setHighlighted(true);
        highlightedEventState = state;
      }

      var boundsSize = stackKey.globalPaintBounds?.height;
      var offset = 0.0;
      if (boundsSize != null) {
        offset = -(boundsSize / 2);
      }

      final eventHeight =
          highlightedEventOffstageKey?.globalPaintBounds?.height;
      if (eventHeight != null) {
        Log.d("Measured height of widget: $eventHeight");
        offset += eventHeight / 2;
      }

      controller.animateTo(offset,
          duration: const Duration(milliseconds: 300),
          curve: Easing.emphasizedDecelerate);

      if (mounted) {
        setState(() {
          highlightedEventOffstageIndex = null;
          highlightedEventOffstageKey = null;
        });
      }
    });

    setState(() {
      recentItemsCount = index;
      historyItemsCount = widget.timeline.events.length - recentItemsCount;
      highlightedEventId = widget.timeline.events[index].eventId;
      highlightedEventOffstageIndex = index;
      highlightedEventOffstageKey = GlobalKey();
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
