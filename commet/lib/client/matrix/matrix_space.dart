import 'package:commet/cache/file_image.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../cache/cache_file_provider.dart';

class MatrixSpace extends Space {
  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;

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

    if (_matrixRoom.avatar != null) {
      var url = _matrixRoom.avatar!
          .getThumbnail(_matrixClient, width: 56, height: 56)
          .toString();
      avatar = NetworkImage(url);
    }

    if (_matrixRoom.avatar != null) {
      avatar = FileImageProvider(
          CacheFileProvider(_matrixRoom.avatar.toString(), () async {
        return (await _matrixClient.httpClient
                .get(_matrixRoom.avatar!.getDownloadLink(_matrixClient)))
            .bodyBytes;
      }));

      avatarThumbnail = FileImageProvider(
          CacheFileProvider.thumbnail(_matrixRoom.avatar.toString(), () async {
        return (await _matrixClient.httpClient.get(_matrixRoom.avatar!
                .getThumbnail(_matrixClient,
                    width: 90, height: 90, animated: true)))
            .bodyBytes;
      }));
    }

    updateRoomsList();
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
  Future<List<PreviewData>> fetchUnjoinedRooms() async {
    List<PreviewData> data = List.empty(growable: true);

    for (var child in _matrixRoom.spaceChildren) {
      if (child.roomId == null) continue;

      if (containsRoom(child.roomId!)) continue;

      if (childPreviews.any((element) => element.roomId == child.roomId)) {
        continue;
      }

      var preview = await _matrixClient.getRoomPreview(child.roomId!);

      if (preview != null) data.add(preview);
    }
    return data;
  }

  @override
  void onRoomReorderedCallback(int oldIndex, int newIndex) {}
}
