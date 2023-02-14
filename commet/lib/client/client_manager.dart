import 'dart:async';

import 'package:commet/client/client.dart';

import '../utils/union.dart';

class ClientManager {
  late final List<Client> _clients = List.empty(growable: true);
  List<Client> get clients => _clients;

  Union<Space> spaces = Union<Space>();
  Union<Room> rooms = Union<Room>();

  late StreamController<void> onSync = StreamController.broadcast();

  void addClient(Client client) {
    _clients.add(client);

    client.onSync.stream.listen((_) => _synced());
    client.rooms.addListeners(onChange: (index) => _updateRoomslist());
    client.spaces.addListeners(onChange: (index) => _updateSpacesList());

    _updateSpacesList();
    _updateRoomslist();
  }

  void log(Object s) {
    print('Client Manager] $s');
  }

  bool isLoggedIn() {
    return _clients[0].isLoggedIn();
  }

  void _synced() {
    log("Syncing");

    _updateRoomslist();
    _updateSpacesList();
    onSync.add(null);
  }

  void _updateRoomslist() {
    for (var client in clients) {
      rooms.addItems(client.rooms.getItems());
    }
  }

  void _updateSpacesList() {
    for (var client in clients) {
      spaces.addItems(client.spaces.getItems());
    }
  }
}
