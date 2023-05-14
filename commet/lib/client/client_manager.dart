import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/stale_info.dart';

class ClientManager {
  final Map<String, Client> _clients = {};

  List<Room> rooms = List.empty(growable: true);
  List<Room> directMessages = List.empty(growable: true);
  List<Space> spaces = List.empty(growable: true);
  final List<Client> _clientsList = List.empty(growable: true);

  List<Client> get clients => _clientsList;

  late StreamController<void> onSync = StreamController.broadcast();

  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<int> onRoomRemoved = StreamController.broadcast();

  late StreamController<int> onDirectMessageRoomAdded =
      StreamController.broadcast();

  late StreamController<int> onSpaceAdded = StreamController.broadcast();
  late StreamController<StaleSpaceInfo> onSpaceRemoved =
      StreamController.broadcast();

  late StreamController<int> onClientAdded = StreamController.broadcast();
  late StreamController<StalePeerInfo> onClientRemoved =
      StreamController.broadcast();

  late StreamController<Space> onSpaceUpdated = StreamController.broadcast();
  late StreamController<Space> onSpaceChildUpdated =
      StreamController.broadcast();

  void addClient(Client client) {
    _clients[client.identifier] = client;

    _clientsList.add(client);
    onClientAdded.add(_clients.length - 1);

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
      addSpace(client, i);
    });
  }

  void addSpace(Client client, int index) {
    var space = client.spaces[index];
    space.onUpdate.stream.listen((_) => spaceUpdated(space));
    space.onChildUpdated.stream.listen((_) => spaceChildUpdated(space));
    spaces.add(client.spaces[index]);
    onSpaceAdded.add(spaces.length - 1);
  }

  void spaceUpdated(Space space) {
    onSpaceUpdated.add(space);
  }

  void spaceChildUpdated(Space space) {
    onSpaceChildUpdated.add(space);
  }

  Future<void> logoutClient(Client client) async {
    int clientIndex = _clientsList.indexOf(client);

    var clientInfo = StalePeerInfo(
        index: clientIndex,
        displayName: client.user!.displayName,
        identifier: client.user!.identifier,
        avatar: client.user!.avatar);

    for (int i = rooms.length - 1; i >= 0; i--) {
      if (rooms[i].client == client) {
        rooms.removeAt(i);
        onRoomRemoved.add(i);
      }
    }

    for (int i = spaces.length - 1; i >= 0; i--) {
      if (spaces[i].client == client) {
        var info = StaleSpaceInfo(
            index: i,
            name: spaces[i].displayName,
            avatar: spaces[i].avatarThumbnail,
            userAvatar: spaces[i].client.user!.avatar);
        spaces.removeAt(i);
        onSpaceRemoved.add(info);
      }
    }

    await client.logout();
    onClientRemoved.add(clientInfo);
    _clients.remove(client.identifier);
    _clientsList.removeAt(clientIndex);
  }

  void removeClient(Client client) {
    if (_clients.containsKey(client.identifier)) {
      _clients.remove(client.identifier);
    }

    if (_clientsList.contains(client)) {
      _clientsList.remove(client);
    }
  }

  bool isLoggedIn() {
    return _clients.values.any((element) => element.isLoggedIn());
  }

  Future<void> close() async {
    for (var client in _clients.values) {
      client.close();
    }
  }

  void _synced() {
    onSync.add(null);
  }
}
