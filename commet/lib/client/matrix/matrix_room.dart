import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  @override
  bool get isMember => _matrixRoom.membership == matrix.Membership.join;

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient) : super(room.id, client) {
    _matrixRoom = room;

    if (room.avatar != null) {
      var url = room.avatar!.getThumbnail(matrixClient, width: 56, height: 56).toString();
      avatar = NetworkImage(url);
    } else {
      avatar = null;
    }

    isDirectMessage = _matrixRoom.isDirectChat;

    if (isDirectMessage) {
      directMessagePartnerID = _matrixRoom.directChatMatrixID!;
    }

    displayName = room.getLocalizedDisplayname();
    notificationCount = room.notificationCount;

    var users = room.getParticipants();

    for (var user in users) {
      if (!this.client.peerExists(user.id)) {
        this.client.addPeer(MatrixPeer(matrixClient, user.id));
      }
    }

    members = List.from(users.map((e) => this.client.getPeer(e.id)), growable: true);

    timeline = MatrixTimeline(client, this, room);

    permissions = MatrixRoomPermissions(_matrixRoom);
  }

  @override
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent? inReplyTo}) async {
    String? id = await _matrixRoom.sendTextEvent(message);
    if (id != null) {
      var event = await _matrixRoom.getEventById(id);
      return (timeline as MatrixTimeline).convertEvent(event!);
    }
    return null;
  }
}
