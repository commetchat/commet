import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;
  late matrix.Timeline _matrixTimeline;

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient) : super(room.id, client) {
    _matrixRoom = room;

    if (room.avatar != null) {
      var url = room.avatar!.getThumbnail(matrixClient, width: 56, height: 56).toString();
      avatar = NetworkImage(url);
    } else {
      avatar = null;
    }

    displayName = room.getLocalizedDisplayname();
    notificationCount = room.notificationCount;

    var users = room.getParticipants();

    for (var user in users) {
      if (!this.client.peerExists(user.id)) {
        this.client.addPeer(MatrixPeer(matrixClient, user.id));
      }
    }

    print("Listening to matrix room sync in room");
    _matrixRoom.client.onSync.stream.listen((event) {
      print("OnSync (Room)");
    });

    _matrixRoom.onUpdate.stream.listen((event) {
      print("onUpdate");
    });

    timeline = MatrixTimeline(client, this, room);
  }
}
