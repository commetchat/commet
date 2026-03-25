import 'dart:async';

import 'package:commet/client/components/message_effects/message_effect_component.dart';
import 'package:commet/client/components/polls/poll_component.dart';
import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_overlay.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final Function(
      {required double offset,
      required double maxScrollExtent,
      required double minScrollExtent})? onViewScrolled;

  @override
  State<RoomTimelineWidgetView> createState() => RoomTimelineWidgetViewState();
}

class RoomTimelineWidgetViewState extends State<RoomTimelineWidgetView> {
  int numBuilds = 0;

  int recentItemsCount = 0;
  int get historyItemsCount => timeline.events.length - recentItemsCount;

  bool firstFrame = true;
  bool animatingToBottom = false;

  late ScrollController controller;
  late List<(GlobalKey, String)> eventKeys;
  late Timeline timeline;

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
  List<StreamSubscription>? subscriptions;

  bool wasLastScrollAttachedToBottom = false;
  bool loading = false;

  bool get attachedToBottom => controller.hasClients
      ? controller.offset - controller.positions.first.minScrollExtent < 50 ||
          animatingToBottom
      : true;

  bool isLoadingFuture = false;
  bool isLoadingHistory = false;

  MessageEffectComponent? effects;

  String get labelTimelineNewMessagesMarker => Intl.message("New messages",
      desc: "Text that is shown below the last read message",
      name: "labelTimelineNewMessagesMarker");

  @override
  void initState() {
    effects = widget.timeline.client.getComponent<MessageEffectComponent>();

    initFromTimeline(widget.timeline);

    controller = ScrollController();
    EventBus.jumpToEvent.stream.listen(jumpToEvent);
    WidgetsBinding.instance.addPostFrameCallback(onAfterFirstFrame);
    super.initState();
  }

  void initFromTimeline(Timeline timeline) {
    if (subscriptions != null) {
      for (var sub in subscriptions!) {
        sub.cancel();
      }
    }

    isLoadingFuture = false;
    isLoadingHistory = false;

    this.timeline = timeline;
    recentItemsCount = timeline.events.length;
    var receipts = timeline.room.getComponent<ReadReceiptComponent>();
    subscriptions = [
      timeline.onEventAdded.stream.listen(onEventAdded),
      timeline.onChange.stream.listen(onEventChanged),
      timeline.onRemove.stream.listen(onEventRemoved),
      timeline.onLoadingStatusChanged.listen(onLoadingStatusChanged),
      if (receipts != null)
        receipts.onReadReceiptsUpdated.listen(onReadReceiptUpdated),
    ];

    if (preferences.messageEffectsEnabled.value) {
      for (int i = 0; i < 5; i++) {
        if (i >= timeline.events.length) break;

        var event = timeline.events[i];
        if (effects?.hasEffect(event) == true) {
          effects?.doEffect(event);
          break;
        }
      }
    }

    eventKeys = List.from(
        timeline.events
            .map((e) => (GlobalKey(debugLabel: e.eventId), e.eventId)),
        growable: true);
  }

  @override
  void dispose() {
    for (var element in subscriptions!) {
      element.cancel();
    }

    super.dispose();
  }

  void onEventAdded(int index) {
    eventKeys.insert(index, (
      GlobalKey(debugLabel: timeline.events[index].eventId),
      timeline.events[index].eventId
    ));

    if (index == 0 || index < recentItemsCount) {
      recentItemsCount += 1;
    }

    if (index == 0) {
      if (attachedToBottom) {
        scrollToBottom();

        widget.markAsRead?.call(timeline.events[0]);
      }

      if (preferences.messageEffectsEnabled.value) {
        effects?.doEffect(timeline.events[index]);
      }
    }

    setState(() {});
  }

  void onEventChanged(int index) {
    var event = timeline.events[index];
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

    if (index == 0) {
      if (attachedToBottom) {
        scrollToBottom();

        widget.markAsRead?.call(timeline.events[0]);
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animateTo(controller.position.minScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutExpo);
    });
  }

  void onEventRemoved(int index) {
    if (index < recentItemsCount) {
      recentItemsCount -= 1;
    }

    var removed = eventKeys.removeAt(index);

    assert(timeline.events[index].eventId == removed.$2);

    setState(() {});
  }

  void onAfterFirstFrame(_) {
    if (controller.hasClients) {
      double extent = controller.position.maxScrollExtent;
      controller = ScrollController(initialScrollOffset: extent);
      scrollViewKey = GlobalKey();
      controller.addListener(onScroll);
      setState(() {
        firstFrame = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jumpToEvent(timeline.room.lastRead, highlight: false);
      onScroll();
    });
  }

  void onScroll() {
    widget.onViewScrolled?.call(
        offset: controller.offset,
        maxScrollExtent: controller.position.maxScrollExtent,
        minScrollExtent: controller.position.minScrollExtent);

    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.setAttachedToBottom(attachedToBottom);

    if (wasLastScrollAttachedToBottom == false && attachedToBottom) {
      widget.onAttachedToBottom?.call();
    }

    wasLastScrollAttachedToBottom = attachedToBottom;

    double loadingThreshold = 500;

    // When the history items are empty, the sliver takes up exactly the height of the viewport, so we should use that height instead
    if (historyItemsCount == 0) {
      var renderBox = stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        loadingThreshold = renderBox.size.height;
      }
    }

    if (controller.offset >
            controller.position.maxScrollExtent - loadingThreshold &&
        !timeline.isLoadingHistory &&
        timeline.canLoadHistory)
      setState(() async {
        await timeline.loadMoreHistory().then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onScroll());
        });
      });

    if (controller.offset <
            (controller.position.minScrollExtent + loadingThreshold) &&
        !timeline.isLoadingFuture &&
        timeline.canLoadFuture)
      setState(() async {
        await timeline.loadMoreFuture();
        eventKeys = List.from(
            timeline.events
                .map((e) => (GlobalKey(debugLabel: e.eventId), e.eventId)),
            growable: true);
      });
  }

  void animateAndSnapToBottom() {
    controller.position.hold(() {});

    setState(() {
      initFromTimeline(widget.timeline);
    });

    var overlayState = overlayKey.currentState as TimelineOverlayState?;
    overlayState?.setAttachedToBottom(attachedToBottom);
    widget.onAttachedToBottom?.call();

    animatingToBottom = true;

    controller
        .animateTo(controller.position.minScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutExpo)
        .then((_) {
      setState(() {
        controller.jumpTo(0);
        animatingToBottom = false;
      });
    });

    setState(() {
      recentItemsCount = 0;
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
        var event = timeline.tryGetEvent(eventId)!;
        overlayState?.setMenu(TimelineEventMenu(
          timeline: timeline,
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

  bool shouldEventShowUnreadMarker(int index) {
    final events = widget.timeline.events;
    final polls = widget.timeline.client.getComponent<PollComponent>();

    bool isHidden(event) =>
        TimelineViewEntryState.eventToDisplayType(event, polls: polls) ==
        TimelineEventWidgetDisplayType.hidden;

    if (index == 0 || events.take(index).every(isHidden)) return false;

    final lastReadIndex =
        events.indexWhere((e) => e.eventId == widget.timeline.room.lastRead);

    if (lastReadIndex > index) return false;
    if (lastReadIndex == index) return true;
    if (!isHidden(events[lastReadIndex])) return false;

    return events.getRange(lastReadIndex, index).every(isHidden);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        onExit: (_) => deselectEvent(),
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
                    if (isLoadingFuture)
                      SliverList(
                          delegate: SliverChildBuilderDelegate(childCount: 1,
                              (BuildContext context, int index) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      })),
                    // The slivers are split into recent and history events and
                    // are rendered separately. This prevents the timeline from
                    // jumping around and allows jumping to specific indices
                    // with more reliability.
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

                          var key;
                          try {
                            key = eventKeys[timelineIndex];
                          } on RangeError {
                            return Placeholder();
                          }
                          assert(
                              key.$2 == timeline.events[timelineIndex].eventId);

                          var showUnreadMarker =
                              shouldEventShowUnreadMarker(timelineIndex);

                          Widget result = Container(
                            alignment: Alignment.center,
                            color: preferences.developerMode.value &&
                                    BuildConfig.DEBUG
                                ? Colors.blue[200 + sliverIndex % 4 * 100]!
                                    .withAlpha(30)
                                : null,
                            child: TimelineViewEntry(
                                key: key.$1,
                                timeline: timeline,
                                onEventHovered: eventHovered,
                                setEditingEvent: widget.setEditingEvent,
                                setReplyingEvent: widget.setReplyingEvent,
                                isThreadTimeline: widget.isThreadTimeline,
                                highlightedEventId: highlightedEventId,
                                overrideShowSender:
                                    showUnreadMarker ? true : null,
                                previewMedia:
                                    widget.timeline.room.shouldPreviewMedia,
                                jumpToEvent: jumpToEvent,
                                initialIndex: timelineIndex),
                          );

                          if (showUnreadMarker)
                            result = newMessagesMarker(result);

                          return result;
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

                          var key;
                          try {
                            key = eventKeys[timelineIndex];
                          } on RangeError {
                            return Placeholder();
                          }
                          assert(
                              key.$2 == timeline.events[timelineIndex].eventId);

                          var showUnreadMarker =
                              shouldEventShowUnreadMarker(timelineIndex);

                          Widget result = Container(
                            alignment: Alignment.center,
                            color: preferences.developerMode.value &&
                                    BuildConfig.DEBUG
                                ? Colors.red[200 + sliverIndex % 4 * 100]!
                                    .withAlpha(30)
                                : null,
                            child: TimelineViewEntry(
                                key: key.$1,
                                onEventHovered: eventHovered,
                                timeline: timeline,
                                setEditingEvent: widget.setEditingEvent,
                                setReplyingEvent: widget.setReplyingEvent,
                                isThreadTimeline: widget.isThreadTimeline,
                                highlightedEventId: highlightedEventId,
                                overrideShowSender:
                                    showUnreadMarker ? true : null,
                                previewMedia:
                                    widget.timeline.room.shouldPreviewMedia,
                                jumpToEvent: jumpToEvent,
                                initialIndex: timelineIndex),
                          );

                          if (showUnreadMarker)
                            result = newMessagesMarker(result);

                          return result;
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
                    if (isLoadingHistory)
                      SliverList(
                          delegate: SliverChildBuilderDelegate(childCount: 1,
                              (BuildContext context, int index) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      })),
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
                          timeline: timeline,
                          isThreadTimeline: widget.isThreadTimeline,
                          initialIndex: highlightedEventOffstageIndex!,
                        ),
                      ),
                    ],
                  ),
                ),
              if (loading)
                Container(
                    color: Colors.black.withAlpha(50),
                    child: const Center(child: CircularProgressIndicator()))
            ],
          ),
        ),
      ),
    );
  }

  Widget newMessagesMarker(Widget child) {
    return Column(
      children: [
        child,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Divider(
                    color: Colors.red,
                    thickness: 4.0,
                    radius: BorderRadiusGeometry.horizontal(
                        right: Radius.circular(16.0)))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(labelTimelineNewMessagesMarker,
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            Expanded(
                child: Divider(
                    color: Colors.red,
                    thickness: 4.0,
                    radius: BorderRadiusGeometry.horizontal(
                        left: Radius.circular(16.0)))),
          ],
        ),
      ],
    );
  }

  void jumpToEvent(String eventId, {bool highlight = true}) async {
    if (highlight && highlightedEventState?.mounted == true) {
      highlightedEventState!.setHighlighted(false);
      highlightedEventState = null;
    }

    int index = timeline.events.indexWhere((event) => event.eventId == eventId);
    if (index == -1) {
      setState(() {
        loading = true;
      });
      var newTimeline =
          await timeline.room.getTimeline(contextEventId: eventId);

      index =
          newTimeline.events.indexWhere((event) => event.eventId == eventId);

      if (index == -1) {
        return;
      }

      setState(() {
        initFromTimeline(newTimeline);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var key = eventKeys[index].$1;
      final state = key.currentState;

      if (highlight && state is TimelineViewEntryState) {
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
      if (highlight) {
        highlightedEventId = timeline.events[index].eventId;
        highlightedEventOffstageIndex = index;
        highlightedEventOffstageKey = GlobalKey();
      }
      loading = false;
    });
  }

  void onLoadingStatusChanged(void event) {
    setState(() {
      isLoadingFuture = timeline.isLoadingFuture;
      isLoadingHistory = timeline.isLoadingHistory;
    });
  }

  void onReadReceiptUpdated(String event) {
    var key = eventKeys.firstWhere(
      (element) => element.$2 == event,
    );

    assert(event == key.$2);

    var state = key.$1.currentState;

    var index = timeline.events.indexWhere((i) => i.eventId == event);

    if (index == -1) {
      Log.w("Could not find the event in the timeline view");
    }

    if (state is TimelineEventViewWidget) {
      (state as TimelineEventViewWidget).update(index);
    } else {
      Log.w("Failed to get state");
    }
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
