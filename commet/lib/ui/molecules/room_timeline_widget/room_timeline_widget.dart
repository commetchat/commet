import 'package:commet/client/timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_widget_view.dart';
import 'package:flutter/material.dart';

class RoomTimelineWidget extends StatefulWidget {
  const RoomTimelineWidget(
      {required this.timeline,
      this.setEditingEvent,
      this.setReplyingEvent,
      super.key});
  final Timeline timeline;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;

  @override
  State<RoomTimelineWidget> createState() => _RoomTimelineWidgetState();
}

class _RoomTimelineWidgetState extends State<RoomTimelineWidget> {
  Future? loadingHistory;

  GlobalKey timelineViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RoomTimelineWidgetView(
      key: timelineViewKey,
      timeline: widget.timeline,
      onViewScrolled: onViewScrolled,
      setReplyingEvent: widget.setReplyingEvent,
      setEditingEvent: widget.setEditingEvent,
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
  }

  void loadMoreHistory() async {
    Log.d("Loading more history!");
    loadingHistory = widget.timeline.loadMoreHistory();
    await loadingHistory;
    loadingHistory = null;
  }
}
