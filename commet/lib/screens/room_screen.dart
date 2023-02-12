import 'package:commet/widgets/custom_scroll.dart';
import 'package:commet/widgets/custom_scroll_bar.dart';
import 'package:flutter/material.dart';

import '../client/client.dart';
import '../widgets/message.dart';

class RoomPage extends StatefulWidget {
  final Room room;
  const RoomPage({required this.room, Key? key}) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late final Future<Timeline> _timelineFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
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

  final TextEditingController _sendController = TextEditingController();

  void _send() {
    widget.room.sendMessage(_sendController.text.trim());
    _sendController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.displayName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Timeline>(
                future: _timelineFuture,
                builder: (context, snapshot) {
                  final timeline = snapshot.data;
                  if (timeline == null) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  _count = timeline.events.length;
                  return Column(
                    children: [
                      // Center(
                      //   child: TextButton(
                      //       //onPressed: timeline.loadMoreHistory(),
                      //       child: const Text('Load more...')),
                      // ),
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
                            initialItemCount: timeline.events.length,
                            itemBuilder: (context, i, animation) =>
                                ScaleTransition(
                                    scale: animation,
                                    child: Message(timeline.events[i])),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: CustomScrollbar(
                            height: 110, scrollController: _scrollController),
                      )
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _sendController,
                    decoration: const InputDecoration(
                      hintText: 'Send message',
                    ),
                  )),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
