import 'dart:async';

import 'package:flutter/material.dart';

enum LoginType {
  loginPassword,
  token,
}

enum EventType {
  message,
  redaction,
  edit,
}

enum LoginResult { success, failed, error }

class TimelineEvent {}

abstract class Timeline {
  late List<TimelineEvent> events;
}

abstract class Room {
  late String identifier;
  late Client client;
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent inReplyTo});

  late ImageProvider? avatar;

  late String displayName;

  int notificationCount = 0;

  Room(this.identifier, this.client);
}

abstract class Client {
  Future<void> init();

  Future<void> logout();

  bool isLoggedIn();

  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token});

  late List<Room> _rooms;

  List<Room> get rooms => _rooms;

  late StreamController<void> onSync;
  late StreamController<void> onRoomListUpdated;
}

class ClientManager {
  late List<Client> _clients;
  List<Client> get clients => _clients;

  late List<Room> _rooms;
  List<Room> get rooms => _rooms;

  late StreamController<void> onSync;
  late StreamController<void> onRoomListUpdated;

  ClientManager() {
    _clients = List.empty(growable: true);
    _rooms = List.empty(growable: true);
    onSync = StreamController<void>();
    onRoomListUpdated = StreamController<void>();
  }

  void addClient(Client client) {
    _clients.add(client);

    client.onSync.stream.listen((_) => _synced());
    client.onRoomListUpdated.stream.listen((_) => _roomListUpdated());

    _updateRoomslist();
  }

  void log(String s) {
    print('Client Manager] $s');
  }

  bool isLoggedIn() {
    return _clients.any((element) => element.isLoggedIn());
  }

  void _synced() {
    log("Syncing");
    _updateRoomslist();
    onSync.add(null);
  }

  void _roomListUpdated() {
    log("Room list updated");
    _updateRoomslist();
    onRoomListUpdated.add(null);
  }

  void _updateRoomslist() {
    for (var client in _clients) {
      var rooms = client.rooms;
      //Add rooms that dont exist in the list
      for (var room in rooms) {
        if (!_rooms.any((element) => element.identifier == room.identifier)) {
          _rooms.add(room);
        }
      }

      //Remove rooms that no longer exist in the list
      for (var room in _rooms.where(
          (element) => !rooms.any((r) => element.identifier == r.identifier))) {
        _rooms.remove(room);
      }

      for (var room in _rooms) {
        log(room.identifier);
      }
    }
  }
}
