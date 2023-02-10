import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom implements Room {
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

  MatrixRoom(this.client, matrix.Room room, matrix.Client matrixClient) {
    identifier = room.id;
    if (room.avatar != null) {
      avatar = NetworkImage(room.avatar!
          .getThumbnail(matrixClient, width: 56, height: 56)
          .toString());
    }

    displayName = room.getLocalizedDisplayname();
    notificationCount = room.notificationCount;
  }

  @override
  Future<TimelineEvent?> sendMessage(String message,
      {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }
}
