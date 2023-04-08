import 'package:commet/ui/molecules/message.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../client/client.dart';

class TimelineViewer extends StatefulWidget {
  final Timeline timeline;
  const TimelineViewer({required this.timeline, Key? key}) : super(key: key);

  @override
  _TimelineViewerState createState() => _TimelineViewerState();
}

class _TimelineViewerState extends State<TimelineViewer> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final ScrollController _scrollController = ScrollController();
  int _count = 0;

  double scrollExtent = 0;

  @override
  void initState() {
    _count = widget.timeline.events.length;
    print("Initial timeline count: $_count");

    widget.timeline!.onEventAdded.stream.listen((index) {
      insertItem(index);
    });

    widget.timeline!.onChange.stream.listen((index) {
      _listKey.currentState?.setState(() {});
    });

    widget.timeline!.onRemove.stream.listen((index) {
      _listKey.currentState?.removeItem(index, (_, __) => const ListTile());
      _count--;
    });

    super.initState();
  }

  void insertItem(int index) {
    _listKey.currentState?.insertItem(index);
    _count++;
  }

  @override
  Widget build(BuildContext context) {
    return buildTimeline(_listKey, _scrollController);
  }

  SafeArea buildTimeline(Key key, ScrollController controller) {
    return SafeArea(
        child: Expanded(
      child: AnimatedList(
          key: key,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          controller: controller,
          initialItemCount: _count,
          itemBuilder: (context, i, animation) {
            return SizeTransition(
                sizeFactor:
                    animation.drive(CurveTween(curve: Curves.easeOutCubic)),
                child: TimelineEventView(event: widget.timeline!.events[i]));
          }),
    ));
  }
}
