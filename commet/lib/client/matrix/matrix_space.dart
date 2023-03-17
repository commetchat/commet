import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixSpace extends Space {
  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;

  MatrixSpace(client, matrix.Room room, matrix.Client matrixClient) : super(room.id, client) {
    _matrixRoom = room;
    _matrixClient = matrixClient;

    displayName = room.getLocalizedDisplayname();

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
      var url = _matrixRoom.avatar!.getThumbnail(_matrixClient, width: 56, height: 56).toString();
      avatar = NetworkImage(url);
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
      }
    }
  }

  @override
  Future<Room> createSpaceChild(String name, RoomVisibility visibility) async {
    var room = await client.createRoom(name, visibility);
    _matrixRoom.setSpaceChild(room.identifier);
    return room;
  }
}
