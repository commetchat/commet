import 'dart:async';

import 'package:commet/client/alert.dart';
import 'package:commet/client/call_manager.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_aggregator.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/client/tasks/client_connection_status_task.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';

class ClientManager {
  final Map<String, Client> _clients = {};

  final NotifyingList<Room> _rooms = NotifyingList.empty(growable: true);

  final NotifyingList<Space> _spaces = NotifyingList.empty(growable: true);

  final AlertManager alertManager = AlertManager();
  late CallManager callManager;

  late final DirectMessagesAggregator directMessages;

  ClientManager() {
    directMessages = DirectMessagesAggregator(this);
    callManager = CallManager(this);
  }

  List<Room> get rooms => _rooms;

  List<Room> singleRooms({Client? filterClient}) {
    var result = List<Room>.empty(growable: true);
    for (var client in clients) {
      if (filterClient != null && client != filterClient) {
        continue;
      }

      var dmComp = client.getComponent<DirectMessagesComponent>();

      for (var room in client.rooms) {
        if (dmComp != null) {
          if (dmComp.isRoomDirectMessage(room)) {
            continue;
          }
        }

        if (client.spaces.any((space) => space.containsRoom(room.identifier))) {
          continue;
        }

        result.add(room);
      }
    }

    return result;
  }

  List<Space> get spaces => _spaces;

  final List<Client> _clientsList = List.empty(growable: true);
  final Map<Client, List<StreamSubscription>> _clientSubscriptions = {};

  List<Client> get clients => _clientsList;

  late StreamController<void> onSync = StreamController.broadcast();

  Stream<int> get onRoomAdded => _rooms.onAdd;

  Stream<int> get onRoomRemoved => _rooms.onRemove;

  Stream<int> get onSpaceAdded => _spaces.onAdd;

  Stream<int> get onSpaceRemoved => _spaces.onRemove;

  late StreamController<int> onClientAdded = StreamController.broadcast();

  late StreamController<StalePeerInfo> onClientRemoved =
      StreamController.broadcast();

  late StreamController<Space> onSpaceUpdated = StreamController.broadcast();
  late StreamController<Space> onSpaceChildUpdated =
      StreamController.broadcast();

  late StreamController<Room> onDirectMessageRoomUpdated =
      StreamController.broadcast();

  // int get directMessagesNotificationCount => directMessages.fold(
  //     0,
  //     (previousValue, element) =>
  //         previousValue + element.displayNotificationCount);

  static Future<ClientManager> init({bool isBackgroundService = false}) async {
    final newClientManager = ClientManager();

    await Future.wait([
      MatrixClient.loadFromDB(newClientManager,
          isBackgroundService: isBackgroundService),
    ]);

    return newClientManager;
  }

  void addClient(Client client) {
    try {
      _clients[client.identifier] = client;

      _clientsList.add(client);

      for (int i = 0; i < client.rooms.length; i++) {
        _onClientAddedRoom(client, i);
      }

      for (int i = 0; i < client.spaces.length; i++) {
        _addSpace(client, i);
      }

      _clientSubscriptions[client] = [
        client.onSync.listen((_) => _synced()),
        client.onRoomAdded.listen((index) => _onClientAddedRoom(client, index)),
        client.onRoomRemoved
            .listen((index) => _onClientRemovedRoom(client, index)),
        client.onSpaceAdded.listen((index) => _addSpace(client, index)),
        client.onSpaceRemoved
            .listen((index) => _onClientRemovedSpace(client, index)),
        client.connectionStatusChanged.stream
            .listen((event) => _onClientConnectionStatusChanged(client, event)),
      ];

      onClientAdded.add(_clients.length - 1);
    } catch (error) {}
  }

  void _onClientConnectionStatusChanged(
      Client client, ClientConnectionStatusUpdate status) {
    if (status.status == ClientConnectionStatus.connected) {
      return;
    }

    if (backgroundTaskManager.tasks
        .whereType<ClientConnectionStatusTask>()
        .where((element) => element.client == client)
        .isEmpty) {
      backgroundTaskManager.addTask(ClientConnectionStatusTask(client, status));
    }
  }

  void _onClientAddedRoom(Client client, int index) {
    rooms.add(client.rooms[index]);
  }

  void _onClientRemovedRoom(Client client, int index) {
    var room = client.rooms[index];
    _rooms.remove(room);
  }

  void _onClientRemovedSpace(Client client, int index) {
    var space = client.spaces[index];
    _spaces.remove(space);
  }

  void _addSpace(Client client, int index) {
    var space = client.spaces[index];
    space.onUpdate.listen((_) => spaceUpdated(space));
    space.onChildRoomUpdated.listen((_) => spaceChildUpdated(space));
    spaces.add(client.spaces[index]);
  }

  void spaceUpdated(Space space) {
    onSpaceUpdated.add(space);
  }

  void spaceChildUpdated(Space space) {
    onSpaceChildUpdated.add(space);
  }

  void directMessageRoomUpdated(Room room) {
    onDirectMessageRoomUpdated.add(room);
  }

  Future<void> logoutClient(Client client) async {
    int clientIndex = _clientsList.indexOf(client);

    var subs = _clientSubscriptions[client];
    if (subs != null) {
      for (var sub in subs) {
        sub.cancel();
      }
      _clientSubscriptions.remove(client);
    }

    var clientInfo = StalePeerInfo(
        index: clientIndex,
        displayName: client.self!.displayName,
        identifier: client.self!.identifier,
        avatar: client.self!.avatar);

    for (int i = rooms.length - 1; i >= 0; i--) {
      if (rooms[i].client == client) {
        rooms.removeAt(i);
      }
    }

    for (int i = spaces.length - 1; i >= 0; i--) {
      if (spaces[i].client == client) {
        spaces.removeAt(i);
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

  Client? getClient(String identifier) {
    var search = clients.where((element) => element.identifier == identifier);
    if (search.isNotEmpty) return search.first;
    return null;
  }
}
