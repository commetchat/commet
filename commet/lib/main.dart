import 'package:commet/screens/login_screen.dart';
import 'package:commet/screens/room_list_screen.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'client/client.dart';
import 'client/matrix/matrix_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clientManager = ClientManager();
  final client = MatrixClient();

  clientManager.addClient(client);

  await client.init();
  runApp(MatrixExampleChat(
    client: clientManager,
  ));
}

class MatrixExampleChat extends StatelessWidget {
  final ClientManager client;
  const MatrixExampleChat({required this.client, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commet',
      builder: (context, child) => Provider<ClientManager>(
        create: (context) => client,
        child: child,
      ),
      home: client.isLoggedIn() ? const RoomListPage() : const LoginPage(),
    );
  }
}

/*
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
    super.initState();
  }

  final TextEditingController _sendController = TextEditingController();

  void _send() {
    widget.room.sendTextEvent(_sendController.text.trim());
    _sendController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.displayname),
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
                      Center(
                        child: TextButton(
                            onPressed: timeline.requestHistory,
                            child: const Text('Load more...')),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: AnimatedList(
                          key: _listKey,
                          reverse: true,
                          initialItemCount: timeline.events.length,
                          itemBuilder: (context, i, animation) => timeline
                                      .events[i].relationshipEventId !=
                                  null
                              ? Container()
                              : ScaleTransition(
                                  scale: animation,
                                  child: Opacity(
                                    opacity: timeline.events[i].status.isSent
                                        ? 1
                                        : 0.5,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        foregroundImage: timeline.events[i]
                                                    .sender.avatarUrl ==
                                                null
                                            ? null
                                            : NetworkImage(timeline
                                                .events[i].sender.avatarUrl!
                                                .getThumbnail(
                                                  widget.room.client,
                                                  width: 56,
                                                  height: 56,
                                                )
                                                .toString()),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(timeline
                                                .events[i].sender
                                                .calcDisplayname()),
                                          ),
                                          Text(
                                            timeline.events[i].originServerTs
                                                .toIso8601String(),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(timeline.events[i]
                                          .getDisplayEvent(timeline)
                                          .body),
                                    ),
                                  ),
                                ),
                        ),
                      ),
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
}*/
