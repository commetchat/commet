import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/preview_data.dart';
import 'package:flutter/material.dart';

abstract class Space {
  late String identifier;
  late Client client;
  late ImageProvider? avatar = null;
  final Map<String, Room> _rooms = {};
  final Map<String, PreviewData> _unjoinedRooms = {};
  late List<Room> rooms = List.empty(growable: true);
  late Key key = UniqueKey();
  late Permissions permissions;

  late String displayName;

  String get topic => "";
  late RoomVisibility visibility = RoomVisibility.private;

  int notificationCount = 0;

  Space(this.identifier, this.client);

  StreamController<void> onUpdate = StreamController.broadcast();

  bool get isMember => false;

  late StreamController<int> onRoomAdded = StreamController.broadcast();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;

    return identifier == other.identifier;
  }

  bool containsRoom(String identifier) {
    return _rooms.containsKey(identifier);
  }

  bool hasUnjoinedRoom(String identifier) {
    return _unjoinedRooms.containsKey(identifier);
  }

  void addUnjoinedRoom(String identifier, PreviewData preview) {
    if (!hasUnjoinedRoom(identifier)) {
      _unjoinedRooms[identifier] = preview;
    }
  }

  void addRoom(Room room) {
    if (!containsRoom(room.identifier)) {
      rooms.add(room);
      _rooms[room.identifier] = room;
      onRoomAdded.add(rooms.length - 1);
      if (_unjoinedRooms.containsKey(room.identifier)) {
        _unjoinedRooms.remove(room.identifier);
      }
    }
  }

  void reorderRooms(int oldIndex, int newIndex) {
    onRoomReorderedCallback(oldIndex, newIndex);

    if (newIndex > oldIndex) {
      newIndex = newIndex - 1;
    }
    final item = rooms.removeAt(oldIndex);
    rooms.insert(newIndex, item);
  }

  Future<List<PreviewData>> getUnjoinedRooms() async {
    await fetchUnjoinedRoomsInternal();
    return _unjoinedRooms.values.toList();
  }

  Future<void> fetchUnjoinedRoomsInternal();

  void onRoomReorderedCallback(int oldIndex, int newIndex) {}

  Future<Room> createSpaceChild(String name, RoomVisibility visibility);
}
