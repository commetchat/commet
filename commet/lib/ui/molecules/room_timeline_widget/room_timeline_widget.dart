import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_widget_view.dart';
import 'package:flutter/material.dart';

class RoomTimelineWidget extends StatefulWidget {
  const RoomTimelineWidget(
      {required this.timeline,
      this.setEditingEvent,
      this.setReplyingEvent,
      this.isThreadTimeline = false,
      this.clearNotifications,
      super.key});
  final Timeline timeline;
  final Function(TimelineEventBase? event)? setReplyingEvent;
  final Function(TimelineEventBase? event)? setEditingEvent;
  final Function(Room room)? clearNotifications;
  final bool isThreadTimeline;

  @override
  State<RoomTimelineWidget> createState() => _RoomTimelineWidgetState();
}

class _RoomTimelineWidgetState extends State<RoomTimelineWidget>
    with WidgetsBindingObserver {
  Future? loadingHistory;

  GlobalKey timelineViewKey = GlobalKey();

  StreamSubscription? sub;

  @override
  void initState() {
    sub = widget.timeline.onEventAdded.stream.listen(onEventReceived);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void onEventReceived(int index) {
    if (index == 0) {
      var state = timelineViewKey.currentState as RoomTimelineWidgetViewState?;
      if (state?.attachedToBottom == true) {
        markAsRead(widget.timeline.events[index]);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      var state = timelineViewKey.currentState as RoomTimelineWidgetViewState?;
      if (state?.attachedToBottom == true) {
        markAsRead(widget.timeline.events.first);
        widget.clearNotifications?.call(widget.timeline.room);
      }
    }

    super.didChangeAppLifecycleState(state);
  }

  Future<void> markAsRead(TimelineEventBase event) async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    widget.timeline.markAsRead(event);
  }

  @override
  Widget build(BuildContext context) {
    return RoomTimelineWidgetView(
      key: timelineViewKey,
      timeline: widget.timeline,
      onViewScrolled: onViewScrolled,
      onAttachedToBottom: onAttachedToBottom,
      isThreadTimeline: widget.isThreadTimeline,
      setReplyingEvent: widget.setReplyingEvent,
      setEditingEvent: widget.setEditingEvent,
      markAsRead: markAsRead,
    );
  }

  void onViewScrolled(
      {required double offset, required double maxScrollExtent}) {
    double loadingThreshold = 500;
    var state = timelineViewKey.currentState as RoomTimelineWidgetViewState?;

    // When the history items are empty, the sliver takes up exactly the height of the viewport, so we should use that height instead
    if (state?.historyItemsCount == 0) {
      var renderBox =
          timelineViewKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        loadingThreshold = renderBox.size.height;
      }
    }

    if (offset > maxScrollExtent - loadingThreshold && loadingHistory == null) {
      loadMoreHistory();
    }

    if (state?.attachedToBottom == true) {}
  }

  void onAttachedToBottom() {
    if (widget.timeline.events.isNotEmpty) {
      markAsRead(widget.timeline.events.first);
      widget.clearNotifications?.call(widget.timeline.room);
    }
  }

  void loadMoreHistory() async {
    loadingHistory = widget.timeline.loadMoreHistory();
    await loadingHistory;
    loadingHistory = null;
  }
}
