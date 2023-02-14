import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../utils/union.dart';

class MatrixSpace implements Space {
  @override
  late Client client;

  @override
  late String identifier;

  @override
  ImageProvider? avatar;

  @override
  late String displayName;

  @override
  int notificationCount = 0;

  @override
  Union<Room> rooms = Union();

  @override
  StreamController<void> onUpdate = StreamController.broadcast();

  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;

  MatrixSpace(this.client, matrix.Room room, matrix.Client matrixClient) {
    _matrixRoom = room;
    _matrixClient = matrixClient;
    identifier = room.id;
    displayName = room.getLocalizedDisplayname();

    room.onUpdate.stream.listen((event) {
      refresh();
      onUpdate.add(null);
    });

    client.onSync.stream.listen((event) {
      refresh();
    });

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
    List<Room> newRooms = List.empty(growable: true);

    for (var child in _matrixRoom.spaceChildren) {
      print(child.roomId);
      newRooms.add(MatrixRoom(
          client, _matrixClient.getRoomById(child.roomId!)!, _matrixClient));
    }

    rooms.addItems(newRooms);
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
