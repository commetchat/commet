import 'package:commet/widgets/custom_scroll.dart';
import 'package:commet/widgets/custom_scroll_bar.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';
import '../../widgets/message.dart';

class TimelineViewer extends StatefulWidget {
  final Room room;
  const TimelineViewer({required this.room, Key? key}) : super(key: key);

  @override
  _TimelineViewerState createState() => _TimelineViewerState();
}

class _TimelineViewerState extends State<TimelineViewer> {
  late Future<Timeline> _timelineFuture;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    print("AKSDLKAJSDLKAS");
    _timelineFuture = widget.room.getTimeline(onChange: (i) {
      print('on change! $i');
      _listKey.currentState?.setState(() {});
    }, onInsert: (i) {
      print('on insert! $i');
      _listKey.currentState?.insertItem(i);
      _count++;
    }, onRemove: (i) {
      print('On remove $i');
      _count--;
      _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
    }, onUpdate: () {
      print('On update');
    });

    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TimelineViewer oldWidget) {
    // TODO: implement didUpdateWidget
    _listKey = GlobalKey<AnimatedListState>();
    _listKey.currentState?.setState(() {});
    _timelineFuture = widget.room.getTimeline(onChange: (i) {
      print('on change! $i');
      _listKey.currentState?.setState(() {});
    }, onInsert: (i) {
      print('on insert! $i');
      _listKey.currentState?.insertItem(i, duration: Duration(seconds: 1));
      _count++;
    }, onRemove: (i) {
      print('On remove $i');
      _count--;
      _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
    }, onUpdate: () {
      print('On update');
    });

    _count = 0;
    super.didUpdateWidget(oldWidget);
  }

  final TextEditingController _sendController = TextEditingController();

  void _send() {
    widget.room.sendMessage(_sendController.text.trim());
    _sendController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Timeline>(
          future: _timelineFuture,
          builder: (context, snapshot) {
            final timeline = snapshot.data;
            if (timeline == null) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            _count = timeline.events.length - 1;

            return Row(
              children: [
                const Divider(height: 1),
                Expanded(
                  child: WebSmoothScroll(
                    controller: _scrollController,
                    animationDuration: 200,
                    child: AnimatedList(
                      key: _listKey,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _scrollController,
                      reverse: true,
                      initialItemCount: _count,
                      itemBuilder: (context, i, animation) =>
                          ScaleTransition(scale: animation, child: Message(timeline.events[i])),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomRight,
                  child: CustomScrollbar(height: 110, scrollController: _scrollController),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
