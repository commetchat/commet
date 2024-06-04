import 'package:commet/client/client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/events/timeline_event_view_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TimelineViewEntry extends StatefulWidget {
  const TimelineViewEntry(
      {required this.timeline, required this.initialIndex, super.key});
  final Timeline timeline;
  final int initialIndex;

  @override
  State<TimelineViewEntry> createState() => TimelineViewEntryState();
}

class TimelineViewEntryState extends State<TimelineViewEntry>
    implements TimelineEventViewWidget {
  late String eventId;
  late EventType eventType;
  late TimelineEventStatus status;
  late int index;

  GlobalKey eventKey = GlobalKey();

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

    if (event != null) {
      return event;
    }

    return TimelineEventView(
        event: widget.timeline.events[index], timeline: widget.timeline);
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
}
