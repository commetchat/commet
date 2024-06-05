import 'package:commet/client/client.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu_dialog.dart';
import 'package:flutter/material.dart';

class TimelineViewEntry extends StatefulWidget {
  const TimelineViewEntry(
      {required this.timeline,
      required this.initialIndex,
      this.onEventHovered,
      this.setEditingEvent,
      this.setReplyingEvent,
      super.key});
  final Timeline timeline;
  final int initialIndex;
  final Function(String eventId)? onEventHovered;
  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;

  @override
  State<TimelineViewEntry> createState() => TimelineViewEntryState();
}

class TimelineViewEntryState extends State<TimelineViewEntry>
    implements TimelineEventViewWidget, SelectableEventViewWidget {
  late String eventId;
  late EventType eventType;
  late TimelineEventStatus status;
  late int index;

  GlobalKey eventKey = GlobalKey();

  bool selected = false;
  LayerLink? timelineLayerLink;

  @override
  void initState() {
    loadState(widget.initialIndex);
    super.initState();
  }

  void loadState(int eventIndex) {
    var event = widget.timeline.events[eventIndex];
    eventId = event.eventId;
    eventType = event.type;
    status = event.status;
    index = eventIndex;
  }

  @override
  void update(int newIndex) {
    index = newIndex;
    // setState(() {
    loadState(newIndex);

    if (eventKey.currentState is TimelineEventViewWidget) {
      (eventKey.currentState as TimelineEventViewWidget).update(newIndex);
    } else {
      Log.w("Failed to get state from event key");
    }
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineEventsBuilt += 1;
    Log.d(
        "Num times timeline event built: ${BenchmarkValues.numTimelineEventsBuilt} ($eventId)");

    if (status == TimelineEventStatus.removed) return Container();

    var event = buildEvent();

    if (Layout.desktop) {
      event = MouseRegion(
        onEnter: (_) =>
            widget.onEventHovered?.call(widget.timeline.events[index].eventId),
        child: event,
      );
    }

    if (Layout.mobile) {
      event = InkWell(
        onLongPress: () {
          var event = widget.timeline.events[index];

          showModalBottomSheet(
              showDragHandle: true,
              isScrollControlled: true,
              elevation: 0,
              context: context,
              builder: (context) => TimelineEventMenuDialog(
                    event: event,
                    timeline: widget.timeline,
                    menu: TimelineEventMenu(
                      timeline: widget.timeline,
                      event: event,
                      setEditingEvent: widget.setEditingEvent,
                      setReplyingEvent: widget.setReplyingEvent,
                      onActionFinished: () => Navigator.of(context).pop(),
                    ),
                  ));
        },
        child: event,
      );
    }

    if (selected) {
      event = Container(
        color: Theme.of(context).hoverColor,
        child: event,
      );
    }

    if (timelineLayerLink != null) {
      event = Stack(
        alignment: Alignment.topRight,
        children: [
          CompositedTransformTarget(
              link: timelineLayerLink!, child: const SizedBox()),
          event ?? Container()
        ],
      );
    }

    return event ?? Container();
  }

  Widget? buildEvent() {
    switch (eventType) {
      case EventType.message:
      case EventType.sticker:
        return TimelineEventViewMessage(
            key: eventKey,
            timeline: widget.timeline,
            initialIndex: widget.initialIndex);
      default:
        return Container(
          key: eventKey,
        );
    }
  }

  @override
  void deselect() {
    setState(() {
      selected = false;
      timelineLayerLink = null;
    });
  }

  @override
  void select(LayerLink link) {
    setState(() {
      selected = true;
      timelineLayerLink = link;
    });
  }
}
