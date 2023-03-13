import 'dart:async';

import 'package:commet/client/client.dart';

class ClientManager {
  final Map<String, Client> _clients = {};

  List<Room> rooms = List.empty(growable: true);
  List<Room> directMessages = List.empty(growable: true);
  List<Space> spaces = List.empty(growable: true);

  late StreamController<void> onSync = StreamController.broadcast();
  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<int> onDirectMessageRoomAdded = StreamController.broadcast();
  late StreamController<int> onSpaceAdded = StreamController.broadcast();

  void addClient(Client client) {
    _clients[client.identifier] = client;

    client.onSync.stream.listen((_) => _synced());

    client.onRoomAdded.stream.listen((i) {
      rooms.add(client.rooms[i]);
      onRoomAdded.add(rooms.length - 1);

      if (client.rooms[i].isDirectMessage) {
        directMessages.add(client.rooms[i]);
        onDirectMessageRoomAdded.add(directMessages.length - 1);
      }
    });

    client.onSpaceAdded.stream.listen((i) {
      spaces.add(client.spaces[i]);
      onSpaceAdded.add(spaces.length - 1);
    });
  }

  List<Client> getClients() {
    return _clients.values.toList();
  }

  bool isLoggedIn() {
    return _clients.values.any((element) => element.isLoggedIn());
  }

  void _synced() {
    onSync.add(null);
  }
}
