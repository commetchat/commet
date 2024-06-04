import 'package:commet/client/client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineViewEntry extends StatefulWidget {
  const TimelineViewEntry(
      {required this.timeline, required this.index, super.key});
  final Timeline timeline;
  final int index;

  @override
  State<TimelineViewEntry> createState() => TimelineViewEntryState();
}

class TimelineViewEntryState extends State<TimelineViewEntry> {
  late String eventId;

  @override
  void initState() {
    var event = widget.timeline.events[widget.index];
    eventId = event.eventId;
    // TODO: implement initState
    super.initState();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineEventsBuilt += 1;
    Log.d(
        "Num times timeline event built: ${BenchmarkValues.numTimelineEventsBuilt}");

    return TimelineEventView(
        event: widget.timeline.events[widget.index], timeline: widget.timeline);
  }
}
