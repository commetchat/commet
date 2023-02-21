import 'dart:async';

import 'package:commet/client/client.dart';

class ClientManager {
  final Map<String, Room> _rooms = Map();
  final Map<String, Space> _spaces = Map();
  final Map<String, Client> _clients = Map();

  List<Room> rooms = List.empty(growable: true);
  List<Space> spaces = List.empty(growable: true);

  late StreamController<void> onSync = StreamController.broadcast();
  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<int> onSpaceAdded = StreamController.broadcast();

  void addClient(Client client) {
    _clients[client.identifier] = client;

    client.onSync.stream.listen((_) => _synced());

    client.onRoomAdded.stream.listen((i) {
      rooms.add(client.rooms[i]);
      onRoomAdded.add(rooms.length - 1);
    });

    client.onSpaceAdded.stream.listen((i) {
      spaces.add(client.spaces[i]);
      onSpaceAdded.add(spaces.length - 1);
    });
  }

  List<Client> getClients() {
    return _clients.values.toList();
  }

  void log(Object s) {
    print('Client Manager] $s');
  }

  bool isLoggedIn() {
    return _clients.values.any((element) => element.isLoggedIn());
  }

  void _synced() {
    log("Syncing");

    onSync.add(null);
  }
}
