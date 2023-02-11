import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({Key? key}) : super(key: key);

  @override
  _RoomListPageState createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  void _logout() async {
    final client = Provider.of<ClientManager>(context, listen: false);
    //await client.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /*
  void _join(Room room) async {
    if (room.membership != Membership.join) {
      await room.join();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomPage(room: room),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ClientManager>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
          itemCount: client.rooms.length,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(foregroundImage: client.rooms[i].avatar),
            title: Row(
              children: [
                Expanded(child: Text(client.rooms[i].displayName)),
                if (client.rooms[i].notificationCount > 0)
                  Material(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child:
                            Text(client.rooms[i].notificationCount.toString()),
                      ))
              ],
            ),
            subtitle: Text(
              'No messages',
              maxLines: 1,
            ),
            //onTap: () => _join(client.rooms[i]),
          ),
        ),
      ),
    );
  }
}
