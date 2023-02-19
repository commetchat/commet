import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';

export 'package:commet/client/room.dart';
export 'package:commet/client/space.dart';
export 'package:commet/client/peer.dart';
export 'package:commet/client/timeline.dart';

enum LoginType {
  loginPassword,
  token,
}

enum LoginResult { success, failed, error }

abstract class Client {
  Future<void> init();

  Future<void> logout();

  final String identifier;

  Client(this.identifier);

  bool isLoggedIn();

  Future<LoginResult> login(LoginType type, String userIdentifier, String server, {String? password, String? token});

  Map<String, Room> _rooms = Map();
  Map<String, Space> _spaces = Map();

  List<Room> rooms = List.empty(growable: true);
  List<Space> spaces = List.empty(growable: true);

  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<int> onSpaceAdded = StreamController.broadcast();

  late StreamController<void> onSync = StreamController.broadcast();

  bool spaceExists(String identifier) {
    return _spaces.containsKey(identifier);
  }

  bool roomExists(String identifier) {
    return _rooms.containsKey(identifier);
  }

  Room? getRoom(String identifier) {
    return _rooms[identifier];
  }

  Space? getSpace(String identifier) {
    return _spaces[identifier];
  }

  void addRoom(Room room) {
    if (!_rooms.containsKey(room.identifier)) {
      _rooms[room.identifier] = room;
      rooms.add(room);
      int index = rooms.length - 1;
      onRoomAdded.add(index);
    }
  }

  void addSpace(Space space) {
    if (!_spaces.containsKey(space.identifier)) {
      _spaces[space.identifier] = space;
      spaces.add(space);
      int index = spaces.length - 1;
      onSpaceAdded.add(index);
    }
  }
}
