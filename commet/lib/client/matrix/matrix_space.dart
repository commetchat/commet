import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixSpace extends Space {
  @override
  StreamController<void> onUpdate = StreamController.broadcast();

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

    print("Listening to onsync stream in MatrixSpace");
    client.onSync.stream.listen((event) {
      refresh();
    });

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
      if (room != null) rooms.add(room);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
