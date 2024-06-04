import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:flutter/material.dart';

class TimelineViewer2 extends StatefulWidget {
  const TimelineViewer2({required this.timeline, super.key});
  final Timeline timeline;
  @override
  State<TimelineViewer2> createState() => _TimelineViewer2State();
}

class _TimelineViewer2State extends State<TimelineViewer2> {
  int numBuilds = 0;

  int recentItemsCount = 0;
  int historyItemsCount = 0;
  late ScrollController controller;

  @override
  void initState() {
    recentItemsCount = widget.timeline.events.length;
    controller = ScrollController(initialScrollOffset: -9999999999);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey<String>('bottom-sliver-list');
    return Scaffold(
      body: CustomScrollView(
        controller: controller,
        reverse: true,
        center: centerKey,
        slivers: <Widget>[
          SliverList(
            // Recent Items
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                int displayIndex = recentItemsCount - index - 1;
                numBuilds += 1;
                print("Num Builds: $numBuilds");
                return Container(
                  alignment: Alignment.center,
                  color: Colors.blue[200 + index % 4 * 100],
                  child: TimelineViewEntry(
                      timeline: widget.timeline, index: displayIndex),
                );
              },
              childCount: recentItemsCount,
            ),
          ),
          SliverList(
            key: centerKey,
            // History Items
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                numBuilds += 1;
                print("Num Builds: $numBuilds");
                var displayIndex = recentItemsCount + index;
                return Container(
                  alignment: Alignment.center,
                  color: Colors.red[200 + index % 4 * 100],
                  child: TimelineViewEntry(
                      timeline: widget.timeline, index: displayIndex),
                );
              },
              childCount: historyItemsCount,
            ),
          ),
        ],
      ),
    );
  }
}
