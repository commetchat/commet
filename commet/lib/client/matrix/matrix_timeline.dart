import 'dart:async';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/atoms/room_created.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/async.dart';
import '../../ui/molecules/message.dart';
import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimeline extends Timeline {
  @override
  late List<TimelineEvent> events;

  late matrix.Timeline? _matrixTimeline;
  late matrix.Room _matrixRoom;
  late Room _room;

  MatrixTimeline(
    Client client,
    Room room,
    matrix.Room matrixRoom,
  ) {
    events = List.empty(growable: true);
    this._matrixRoom = matrixRoom;
    this.client = client;
    this._room = room;

    initTimeline();
  }

  void initTimeline() async {
    _matrixTimeline = await _matrixRoom.getTimeline(
      onInsert: (index) async {
        insertEvent(index, await convertEvent(_matrixTimeline!.events[index], _matrixTimeline!));
      },
    );
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var converted = await convertEvent(_matrixTimeline!.events[i], _matrixTimeline!);
      insertEvent(i, converted);
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

    switch (event.type) {
      case matrix.EventTypes.Message:
        e.widget = Message(e);
        break;
      case matrix.EventTypes.RoomCreate:
        e.widget = RoomCreated(this._room);
        break;
      case matrix.EventTypes.RoomMember:
        e.widget = GenericRoomEvent(event.content['displayname'] + " Joined the room", Icons.person_add_alt_1);
        break;
      case matrix.EventTypes.HistoryVisibility:
        e.widget = GenericRoomEvent(
            "${event.senderId} Set history visibility to: ${event.content['history_visibility']}",
            Icons.bookmark_outline_rounded);
        break;
      case matrix.EventTypes.GuestAccess:
        e.widget = GenericRoomEvent(
            "${event.senderId} Set guest access to: ${event.content['guest_access']}", Icons.bookmark_outline_rounded);
        break;
      case matrix.EventTypes.RoomName:
        e.widget = GenericRoomEvent(
            "${event.senderId} Set room name to: ${event.content['name']}", Icons.bookmark_outline_rounded);
        break;
      case matrix.EventTypes.Encryption:
        e.widget = GenericRoomEvent("${event.senderId} Enabled Encryption", Icons.lock);
        break;
      default:
        e.widget = null;
        break;
    }

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
  Future<void> loadMoreHistory() async {
    if (_matrixTimeline!.canRequestHistory) return await _matrixTimeline!.requestHistory();
  }
}
