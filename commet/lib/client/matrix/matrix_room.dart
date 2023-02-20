import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;
  late matrix.Timeline _matrixTimeline;

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient) : super(room.id, client) {
    _matrixRoom = room;
    timeline = MatrixTimeline();

    if (room.avatar != null) {
      var url = room.avatar!.getThumbnail(matrixClient, width: 56, height: 56).toString();
      avatar = NetworkImage(url);
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

    initTimeline();
  }

  void initTimeline() async {
    _matrixTimeline = await _matrixRoom.getTimeline(
      onInsert: (index) async {
        timeline!.insertEvent(index, await convertEvent(_matrixTimeline.events[index], _matrixTimeline));
      },
    );
    for (int i = 0; i < _matrixTimeline.events.length; i++) {
      var converted = await convertEvent(_matrixTimeline.events[i], _matrixTimeline);
      timeline!.insertEvent(i, converted);
    }
  }

  Future<TimelineEvent> convertEvent(matrix.Event event, matrix.Timeline timeline) async {
    TimelineEvent e = TimelineEvent();

    e.eventId = event.eventId;
    e.originServerTs = event.originServerTs;
    event.status.isSent;

    if (client.peerExists(event.senderId)) {
      e.sender = client.getPeer(event.senderId)!;
    }

    e.body = event.getDisplayEvent(timeline).body;

    switch (event.status) {
      case matrix.EventStatus.removed:
        e.status = TimelineEventStatus.removed;
        break;
      case matrix.EventStatus.error:
        e.status = TimelineEventStatus.error;
        break;
      case matrix.EventStatus.sending:
        e.status = TimelineEventStatus.sending;
        break;
      case matrix.EventStatus.sent:
        e.status = TimelineEventStatus.sent;
        break;
      case matrix.EventStatus.synced:
        e.status = TimelineEventStatus.synced;
        break;
      case matrix.EventStatus.roomState:
        e.status = TimelineEventStatus.roomState;
        break;
    }

    return e;
  }

  @override
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }
}
