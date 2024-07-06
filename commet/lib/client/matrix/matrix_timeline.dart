import 'dart:async';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/matrix_timeline_event.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'matrix_client.dart';

class MatrixTimeline extends Timeline {
  matrix.Timeline? _matrixTimeline;
  late matrix.Room _matrixRoom;

  matrix.Timeline? get matrixTimeline => _matrixTimeline;

  MatrixTimeline(
    Client client,
    Room room,
    matrix.Room matrixRoom, {
    matrix.Timeline? initialTimeline,
  }) {
    events = List.empty(growable: true);
    _matrixRoom = matrixRoom;
    this.client = client;
    this.room = room;
    _matrixTimeline = initialTimeline;

    if (_matrixTimeline != null) {
      convertAllTimelineEvents();
    }
  }

  Future<void> initTimeline() async {
    await (client as MatrixClient).firstSync;

    _matrixTimeline = await _matrixRoom.getTimeline(
      onInsert: onEventInserted,
      onChange: onEventChanged,
      onRemove: onEventRemoved,
    );

    // This could maybe make load times realllly slow if we have a ton of stuff in the cache?
    // Might be better to only convert as many as we would need to display immediately and then convert the rest on demand
    convertAllTimelineEvents();
  }

  void convertAllTimelineEvents() {
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var converted = MatrixTimelineEvent(
          _matrixTimeline!.events[i], _matrixTimeline!.room.client,
          timeline: _matrixTimeline);
      insertEvent(i, converted);
    }
  }

  void onEventInserted(index) {
    if (_matrixTimeline == null) return;
    insertEvent(
        index,
        MatrixTimelineEvent(
            _matrixTimeline!.events[index], _matrixTimeline!.room.client,
            timeline: _matrixTimeline));
  }

  void onEventChanged(index) {
    if (_matrixTimeline == null) return;

    if (index < _matrixTimeline!.events.length) {
      (events[index] as MatrixTimelineEvent).convertEvent(
          _matrixTimeline!.events[index], _matrixTimeline!.room.client,
          timeline: _matrixTimeline);

      notifyChanged(index);
    }
  }

  void onEventRemoved(index) {
    events.removeAt(index);
    onRemove.add(index);
  }

  @override
  Future<void> loadMoreHistory() async {
    if (_matrixTimeline?.canRequestHistory == true) {
      return await _matrixTimeline!.requestHistory();
    }
  }

  @override
  void markAsRead(TimelineEvent event) async {
    if (event.type == EventType.edit ||
        event.status == TimelineEventStatus.synced) {
      _matrixTimeline?.setReadMarker();
    }
  }

  @override
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId) async {
    var event = await _matrixRoom.getEventById(eventId);
    if (event == null) return null;
    return MatrixTimelineEvent(event, _matrixRoom.client,
        timeline: _matrixTimeline);
  }

  Future<void> removeReaction(
      TimelineEvent reactingTo, Emoticon reaction) async {
    var event = await _matrixRoom.getEventById(reactingTo.eventId);
    if (event == null) return;

    if (!event.hasAggregatedEvents(
        _matrixTimeline!, matrix.RelationshipTypes.reaction)) return;

    var events = event
        .aggregatedEvents(_matrixTimeline!, matrix.RelationshipTypes.reaction)
        .where((element) => element.senderId == _matrixRoom.client.userID);

    for (var e in events) {
      if (!e.content.containsKey("m.relates_to")) continue;
      var content = e.content["m.relates_to"] as Map<String, Object?>;

      if (content.containsKey("key") && content["key"] == reaction.key) {
        await _matrixRoom.redactEvent(e.eventId);
        return;
      }
    }
  }

  @override
  Future<void> deleteEvent(TimelineEvent event) async {
    var matrixEvent = await _matrixTimeline!.getEventById(event.eventId);
    if (event.status == TimelineEventStatus.error) {
      await matrixEvent?.cancelSend();
    } else {
      await _matrixRoom.redactEvent(event.eventId);
    }
  }

  @override
  bool canDeleteEvent(TimelineEvent event) {
    if (event.senderId != room.client.self!.identifier &&
        room.permissions.canDeleteOtherUserMessages != true) return false;

    if (![EventType.message, EventType.sticker].contains(event.type))
      return false;

    return true;
  }

  @override
  Future<void> close() async {
    _matrixTimeline?.cancelSubscriptions();
    await onEventAdded.close();
    await onChange.close();
    await onRemove.close();
  }
}
