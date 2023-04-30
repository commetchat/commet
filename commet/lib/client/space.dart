import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/stale_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class Space {
  Space(this.identifier, this.client);

  late String identifier;
  late Client client;
  late Key key = UniqueKey();

  late Permissions permissions;

  late String displayName;
  ImageProvider? get avatar => _avatar;
  ImageProvider? get avatarThumbnail => _avatarThumbnail;

  ImageProvider? _avatar;
  ImageProvider? _avatarThumbnail;

  late List<Room> rooms = List.empty(growable: true);

  String get topic => "";

  late RoomVisibility visibility = RoomVisibility.private;

  int notificationCount = 0;

  String get localId => "${client.identifier}:$identifier";
  List<RoomPreview> get childPreviews => _childPreviewsList;

  StreamController<void> onUpdate = StreamController.broadcast();
  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<void> onChildrenUpdated = StreamController.broadcast();
  late StreamController<int> onChildPreviewAdded = StreamController.broadcast();

  late StreamController<StaleRoomInfo> onChildPreviewRemoved =
      StreamController.broadcast();
  late StreamController<void> onChildPreviewsUpdated =
      StreamController.broadcast();

  final Map<String, Room> _rooms = {};

  final List<RoomPreview> _childPreviewsList = List.empty(growable: true);

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
    for (int i = _childPreviewsList.length - 1; i >= 0; i--) {
      if (_childPreviewsList[i].roomId == room.identifier) {
        onChildPreviewRemoved.add(StaleRoomInfo(
            index: i,
            avatar: _childPreviewsList[i].avatar,
            name: _childPreviewsList[i].displayName,
            topic: _childPreviewsList[i].topic));
        _childPreviewsList.removeAt(i);
      }
    }

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
    var previews = await fetchChildren();

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
  Future<List<RoomPreview>> fetchChildren();

  Future<Room> createRoom(String name, RoomVisibility visibility);

  Future<void> loadExtra() async {
    var childFuture = _updateChildPreviews();

    await childFuture;
    loaded = true;
  }

  Future<void> setDisplayName(String newName) async {
    await setDisplayNameInternal(newName);
    displayName = newName;
    onUpdate.add(null);
  }

  @protected
  Future<void> setDisplayNameInternal(String name);

  Future<void> changeAvatar(Uint8List bytes, String? mimeType);

  @protected
  void setAvatar({ImageProvider? newAvatar, ImageProvider? newThumbnail}) {
    onUpdate.add(null);
    if (newAvatar != null) {
      _avatar = newAvatar;
      _avatarThumbnail = newThumbnail;
    }

    if (newThumbnail != null) {
      _avatarThumbnail = newThumbnail;
    }
  }
}
