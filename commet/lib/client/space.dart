import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';

abstract class Space {
  Space(this.identifier, this.client);

  late String identifier;
  late Client client;
  late Key key = UniqueKey();

  late Permissions permissions;

  late String displayName;
  ImageProvider? avatar;
  ImageProvider? avatarThumbnail;

  late List<Room> rooms = List.empty(growable: true);

  String get topic => "";

  late RoomVisibility visibility = RoomVisibility.private;

  int notificationCount = 0;

  String get localId => "${client.identifier}:$identifier";
  List<PreviewData> get childPreviews => _childPreviewsList;

  StreamController<void> onUpdate = StreamController.broadcast();
  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<void> onChildrenUpdated = StreamController.broadcast();

  late StreamController<int> onChildPreviewAdded = StreamController.broadcast();

  late StreamController<int> onChildPreviewRemoved =
      StreamController.broadcast();
  late StreamController<void> onChildPreviewsUpdated =
      StreamController.broadcast();

  final Map<String, Room> _rooms = {};

  final List<PreviewData> _childPreviewsList = List.empty(growable: true);

  bool loaded = false;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;
    if (other.client != client) return false;

    return identifier == other.identifier;
  }

  bool containsRoom(String identifier) {
    return _rooms.containsKey(identifier);
  }

  void addRoom(Room room) {
    if (!containsRoom(room.identifier)) {
      rooms.add(room);
      _rooms[room.identifier] = room;
      onRoomAdded.add(rooms.length - 1);
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

  Future<void> _updateChildPreviews() async {
    var previews = await fetchUnjoinedRooms();
    for (var preview in previews) {
      if (_childPreviewsList
          .any((element) => element.roomId == preview.roomId)) {
        continue;
      }

      _childPreviewsList.add(preview);
      onChildPreviewAdded.add(_childPreviewsList.length - 1);
    }
  }

  @protected
  void onRoomReorderedCallback(int oldIndex, int newIndex);

  @protected
  Future<List<PreviewData>> fetchUnjoinedRooms();

  Future<Room> createRoom(String name, RoomVisibility visibility);

  Future<void> loadExtra() async {
    var childFuture = _updateChildPreviews();

    await childFuture;
    loaded = true;
  }
}
