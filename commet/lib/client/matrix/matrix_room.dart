import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoom extends Room {
  late matrix.Room _matrixRoom;

  late Timeline _timeline;

  MatrixRoom(client, matrix.Room room, matrix.Client matrixClient) : super(room.id, client) {
    _matrixRoom = room;

    if (room.avatar != null) {
      var url = room.avatar!.getThumbnail(matrixClient, width: 56, height: 56).toString();
      avatar = NetworkImage(url);
    }

    displayName = room.getLocalizedDisplayname();
    notificationCount = room.notificationCount;

    print("Listening to matrix room sync in room");
    _matrixRoom.client.onSync.stream.listen((event) {
      print("OnSync (Room)");
    });

    _matrixRoom.onUpdate.stream.listen((event) {
      print("onUpdate");
    });
  }

  Function(int index)? onInsert;

  @override
  Future<Timeline> getTimeline(
      {void Function(int index)? onChange,
      void Function(int index)? onRemove,
      void Function(int insertID)? onInsert,
      void Function()? onNewEvent,
      void Function()? onUpdate,
      String? eventContextId}) async {
    this.onInsert = onInsert;

    var timeline = await _matrixRoom.getTimeline(
        onChange: (val) => {onChange?.call(val), print("onChange")},
        onRemove: (val) => {onRemove?.call(val), print("onRemove")},
        onInsert: (val) => _insertMessage(val),
        onNewEvent: () => {onNewEvent?.call(), print("onNewEvent")},
        onUpdate: () => {onUpdate?.call(), print("onUpdate")});

    _timeline = await convertMatrixTimeline(timeline);

    return _timeline;
  }

  void _insertMessage(int index) async {
    print("Inserting message at index: $index");
    var timeline = await _matrixRoom.getTimeline();
    var event = await convertEvent(timeline.events[index], timeline);

    _timeline.events.insert(index, event);
    onInsert?.call(index);
  }

  Future<Timeline> convertMatrixTimeline(matrix.Timeline timeline) async {
    Timeline t = MatrixTimeline();
    for (var event in timeline.events) {
      var e = await convertEvent(event, timeline);
      t.events.add(e);
    }
    return t;
  }

  Future<TimelineEvent> convertEvent(matrix.Event event, matrix.Timeline timeline) async {
    TimelineEvent e = TimelineEvent();

    e.eventId = event.eventId;
    e.originServerTs = event.originServerTs;
    event.status.isSent;
    var user = await event.fetchSenderUser();
    e.sender = MatrixPeer(client, event.senderId, user!.calcDisplayname(), null);

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
