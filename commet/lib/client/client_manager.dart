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
import 'package:commet/utils/notifying_map.dart';
import 'package:commet/utils/notifying_sub_map.dart';

class ClientManager {
  final NotifyingMap<String, BaseRoom> _all_rooms = NotifyingMap();

  final NotifyingMap<String, Client> _clients = NotifyingMap();

  late final NotifyingMap<String, Room> _rooms =
      NotifyingSubMap(_all_rooms, null);

  late final NotifyingMap<String, Space> _spaces =
      NotifyingSubMap(_all_rooms, null);

  NotifyingMap<String, Room> get motifyingMapRoom => _rooms;
  NotifyingMap<String, Space> get motifyingMapSpace => _spaces;

  final AlertManager alertManager = AlertManager();
  late CallManager callManager;

  late final DirectMessagesAggregator directMessages;

  static final ClientManager instance = ClientManager._();

  ClientManager._() {
    directMessages = DirectMessagesAggregator(this);
    callManager = CallManager(this);
  }

  Iterable<Room> get rooms => _rooms.values;

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

        if (client.spaces.any((space) => space.containsRoom(room.roomId))) {
          continue;
        }

        result.add(room);
      }
    }

    return result;
  }

  Iterable<Space> get spaces => _spaces.values;

  final List<Client> _clientsList = List.empty(growable: true);
  final Map<Client, List<StreamSubscription>> _clientSubscriptions = {};

  List<Client> get clients => _clientsList;

  late StreamController<void> onSync = StreamController.broadcast();

  Stream<Room> get onRoomAdded => _rooms.onAdd.map((e) => e.value);

  Stream<Room> get onRoomRemoved => _rooms.onRemove.map((e) => e.value);

  Stream<Space> get onSpaceAdded => _spaces.onAdd.map((e) => e.value);

  Stream<Space> get onSpaceRemoved => _spaces.onRemove.map((e) => e.value);

  Stream<Client> get onClientAdded => _clients.onAdd.map((e) => e.value);

  Stream<Client> get onClientRemoved => _clients.onRemove.map((e) => e.value);

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
    await Future.wait([
      MatrixClient.loadFromDB(instance,
          isBackgroundService: isBackgroundService),
    ]);

    return instance;
  }

  void addClient(Client client) {
    try {
      _clients[client.identifier] = client;

      _clientsList.add(client);

      for (final e in client.spaces) {
        _addSpace(client, e);
      }

      _clientSubscriptions[client] = [
        client.onSync.listen((_) => _synced()),
        client.onSpaceAdded.listen((space) => _addSpace(client, space)),
        client.connectionStatusChanged.stream
            .listen((event) => _onClientConnectionStatusChanged(client, event)),
      ];
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

  void _addSpace(Client client, Space space) {
    space.onUpdate.listen((_) => spaceUpdated(space));
    space.onChildRoomUpdated.listen((_) => spaceChildUpdated(space));
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

    for (final room in rooms) {
      if (room.client == client) {
        _rooms.remove(room.localId);
      }
    }

    for (final space in spaces) {
      if (space.client == client) {
        _spaces.remove(space.localId);
      }
    }

    await client.logout();
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
