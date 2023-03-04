import 'package:commet/ui/molecules/message.dart';
import 'package:commet/widgets/custom_scroll.dart';
import 'package:commet/widgets/custom_scroll_bar.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';

class TimelineViewer extends StatefulWidget {
  final Room room;
  const TimelineViewer({required this.room, Key? key}) : super(key: key);

  @override
  _TimelineViewerState createState() => _TimelineViewerState();
}

class _TimelineViewerState extends State<TimelineViewer> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  @override
  void initState() {
    _count = widget.room.timeline!.events.length;
    widget.room.timeline!.onEventAdded.stream.listen((index) {
      _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 500));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Row(
        children: [
          const Divider(height: 1),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              reverse: true,
              physics: BouncingScrollPhysics(),
              initialItemCount: _count,
              itemBuilder: (context, i, animation) => SizeTransition(
                  sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
                  child: Message(
                    widget.room.timeline!.events[i],
                    showSender: true,
                  )),
            ),
          ),
        ],
      )),
    );
  }
}
