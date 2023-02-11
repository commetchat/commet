import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
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

  late matrix.Room _matrixRoom;

  MatrixRoom(this.client, matrix.Room room, matrix.Client matrixClient) {
    identifier = room.id;
    _matrixRoom = room;

    if (room.avatar != null) {
      var url = room.avatar!
          .getThumbnail(matrixClient, width: 56, height: 56)
          .toString();
      avatar = NetworkImage(url);
    }

    displayName = room.getLocalizedDisplayname();
    notificationCount = room.notificationCount;
  }

  @override
  Future<Timeline> getTimeline(
      {void Function(int index)? onChange,
      void Function(int index)? onRemove,
      void Function(int insertID)? onInsert,
      void Function()? onNewEvent,
      void Function()? onUpdate,
      String? eventContextId}) async {
    return _matrixRoom
        .getTimeline(
            onChange: (val) => {onChange!(val)},
            onRemove: (val) => {onRemove!(val)},
            onInsert: (val) => {onInsert!(val)},
            onNewEvent: () => {onNewEvent!()},
            onUpdate: () => {onUpdate!()})
        .then((value) => convertMatrixTimeline(value));
  }

  Future<Timeline> convertMatrixTimeline(matrix.Timeline timeline) async {
    Timeline t = MatrixTimeline();

    for (var event in timeline.events) {
      TimelineEvent e = TimelineEvent();

      e.eventId = event.eventId;
      e.originServerTs = event.originServerTs;
      event.status.isSent;
      var user = await event.fetchSenderUser();
      e.sender =
          MatrixPeer(client, event.senderId, user!.calcDisplayname(), null);

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

      t.events.add(e);
    }

    return t;
  }

  @override
  Future<TimelineEvent?> sendMessage(String message,
      {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }
}
