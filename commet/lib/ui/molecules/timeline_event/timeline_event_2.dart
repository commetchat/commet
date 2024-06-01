import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEvent2 extends StatefulWidget {
  const TimelineEvent2(
      {super.key, required this.timeline, required this.eventIndex});
  final Timeline timeline;
  final int eventIndex;
  @override
  State<TimelineEvent2> createState() => _TimelineEvent2State();
}

class _TimelineEvent2State extends State<TimelineEvent2> {
  late TimelineEvent event;

  @override
  void initState() {
    event = widget.timeline.events[widget.eventIndex];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (event.type == EventType.message) {
      return tiamat.Text(event.body!);
    } else {
      return const Placeholder(fallbackHeight: 10);
    }
  }
}
