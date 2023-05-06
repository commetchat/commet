import 'dart:typed_data';

import 'package:commet/cache/file_image.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_room_preview.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../cache/cache_file_provider.dart';

class MatrixSpace extends Space {
  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;
  Uri? _avatarUrl;
  bool ignoreNextAvatarUpdate = false;

  @override
  String get topic => _matrixRoom.topic;

  @override
  RoomVisibility get visibility {
    switch (_matrixRoom.joinRules) {
      case matrix.JoinRules.public:
        return RoomVisibility.public;
      case matrix.JoinRules.knock:
        return RoomVisibility.knock;
      case matrix.JoinRules.invite:
        return RoomVisibility.invite;
      case matrix.JoinRules.private:
        return RoomVisibility.private;
      default:
        return RoomVisibility.private;
    }
  }

  MatrixSpace(client, matrix.Room room, matrix.Client matrixClient)
      : super(room.id, client) {
    _matrixRoom = room;
    _matrixClient = matrixClient;
    displayName = room.getLocalizedDisplayname();

    _matrixRoom.postLoad();

    room.onUpdate.stream.listen((event) {
      refresh();
      onUpdate.add(null);
    });

    client.onSync.stream.listen((event) {
      refresh();
    });

    permissions = MatrixRoomPermissions(_matrixRoom);
    refresh();
  }

  void refresh() {
    displayName = _matrixRoom.getLocalizedDisplayname();

    if (_matrixRoom.avatar != null && _matrixRoom.avatar != _avatarUrl) {
      updateAvatarFromRoomState();
    }

    updateRoomsList();
  }

  void updateAvatarFromRoomState() {
    _avatarUrl = _matrixRoom.avatar;
    if (ignoreNextAvatarUpdate) {
      ignoreNextAvatarUpdate = false;
      return;
    }
    if (_matrixRoom.avatar != null) {
      var url = _matrixRoom.avatar!
          .getThumbnail(_matrixClient, width: 56, height: 56)
          .toString();
      var avatar = NetworkImage(url);
      setAvatar(newAvatar: avatar);
    }

    if (_matrixRoom.avatar != null) {
      updateAvatar();
    }
  }

  void updateAvatar() {
    var avatar = FileImageProvider(
        CacheFileProvider(_matrixRoom.avatar.toString(), () async {
      return (await _matrixClient.httpClient
              .get(_matrixRoom.avatar!.getDownloadLink(_matrixClient)))
          .bodyBytes;
    }));

    var avatarThumbnail = FileImageProvider(
        CacheFileProvider.thumbnail(_matrixRoom.avatar.toString(), () async {
      return (await _matrixClient.httpClient.get(_matrixRoom.avatar!
              .getThumbnail(_matrixClient,
                  width: 90, height: 90, animated: true)))
          .bodyBytes;
    }));

    setAvatar(newAvatar: avatar, newThumbnail: avatarThumbnail);
  }

  void updateRoomsList() {
    for (var child in _matrixRoom.spaceChildren) {
      // reuse the existing room object
      var room = client.getRoom(child.roomId!);
      if (room != null) {
        if (!containsRoom(room.identifier)) {
          addRoom(room);
        }
      } else {}
    }
  }

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility) async {
    var room = await client.createRoom(name, visibility);
    _matrixRoom.setSpaceChild(room.identifier);
    return room;
  }

  @override
  Future<List<RoomPreview>> fetchChildren() async {
    var response =
        await _matrixClient.getSpaceHierarchy(identifier, maxDepth: 5);

    return response.rooms
        .where((element) => element.roomId != identifier)
        .where((element) => !containsRoom(element.roomId))
        .map((e) => MatrixSpaceRoomChunkPreview(e, _matrixClient))
        .toList();
  }

  @override
  void onRoomReorderedCallback(int oldIndex, int newIndex) {}

  @override
  Future<void> setDisplayNameInternal(String name) async {
    await _matrixRoom.setName(name);
  }

  @override
  Future<void> changeAvatar(Uint8List bytes, String? mimeType) async {
    var avatar = Image.memory(bytes).image;
    ignoreNextAvatarUpdate = true;
    setAvatar(newAvatar: avatar, newThumbnail: avatar);

    await _matrixRoom.setAvatar(matrix.MatrixImageFile(
        bytes: bytes,
        name: "avatar",
        mimeType: mimeType == "" ? null : mimeType));
  }

  @override
  Future<void> setSpaceChildRoomInternal(Room room) async {
    if (room is! MatrixRoom) {
      throw Exception("Invalid room type for this client");
    }

    await _matrixRoom.setSpaceChild(room.identifier);
  }
}
