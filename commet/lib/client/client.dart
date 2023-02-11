import 'dart:async';
import 'dart:math';

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

  void log(Object s) {
    print('Client Manager] $s');
  }

  bool isLoggedIn() {
    return _clients[0].isLoggedIn();
    //return _clients.any((element) => element.isLoggedIn());
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
    var allRooms = List.empty(growable: true);

    for (var client in _clients) {
      allRooms.addAll(client.rooms);
    }

    var addRooms = allRooms.where((room) => !_rooms.any((e) =>
        e.runtimeType == room.runtimeType && e.identifier == room.identifier));

    log(addRooms);
    for (var room in addRooms) {
      _rooms.add(room);
    }

    var removeRooms = _rooms.where((room) => !allRooms.any((e) =>
        (e.runtimeType == room.runtimeType &&
            e.identifier == room.identifier)));

    log(removeRooms);

    for (var room in removeRooms) {
      log(room.runtimeType);
      _rooms.remove(room);
    }

    for (var room in _rooms) {
      log(room.identifier);
    }
  }
}
