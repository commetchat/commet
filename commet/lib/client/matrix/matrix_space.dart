import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

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
  late List<Room> rooms;

  late matrix.Room _matrixRoom;

  MatrixSpace(this.client, matrix.Room room, matrix.Client matrixClient) {
    _matrixRoom = room;
    identifier = room.id;
    displayName = room.getLocalizedDisplayname();

    if (room.avatar != null) {
      var url = room.avatar!
          .getThumbnail(matrixClient, width: 56, height: 56)
          .toString();
      avatar = NetworkImage(url);
    }
  }
}
