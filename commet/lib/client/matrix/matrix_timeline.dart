import 'dart:async';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimeline extends Timeline {
  matrix.Timeline? _matrixTimeline;
  late matrix.Room _matrixRoom;

  late MatrixRoom _room;

  final StreamController<void> _loadingStatusChangedController =
      StreamController.broadcast();

  @override
  Stream<void> get onLoadingStatusChanged =>
      _loadingStatusChangedController.stream;

  matrix.Timeline? get matrixTimeline => _matrixTimeline;

  MatrixTimeline(
    MatrixClient client,
    MatrixRoom room,
    matrix.Room matrixRoom, {
    matrix.Timeline? initialTimeline,
  }) {
    events = List.empty(growable: true);
    _matrixRoom = matrixRoom;
    this.client = client;
    this.room = room;
    _room = room;
    _matrixTimeline = initialTimeline;

    if (_matrixTimeline != null) {
      convertAllTimelineEvents();
    }
  }

  Future<void> initTimeline({String? contextEventId}) async {
    _matrixTimeline = await _matrixRoom.getTimeline(
        onInsert: onEventInserted,
        onChange: onEventChanged,
        onRemove: onEventRemoved,
        eventContextId: contextEventId);

    // This could maybe make load times realllly slow if we have a ton of stuff in the cache?
    // Might be better to only convert as many as we would need to display immediately and then convert the rest on demand
    convertAllTimelineEvents();
  }

  void convertAllTimelineEvents() {
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var converted = _room.convertEvent(_matrixTimeline!.events[i]);
      insertEvent(i, converted);
    }
  }

  void onEventInserted(index) {
    if (_matrixTimeline == null) return;
    insertEvent(index, _room.convertEvent(_matrixTimeline!.events[index]));
  }

  void onEventChanged(index) {
    if (_matrixTimeline == null) return;

    if (index < _matrixTimeline!.events.length) {
      events[index] = (room as MatrixRoom).convertEvent(
          _matrixTimeline!.events[index],
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
      var f = _matrixTimeline!.requestHistory();
      _loadingStatusChangedController.add(null);

      await f;
    }
  }

  @override
  bool get canLoadFuture => _matrixTimeline?.canRequestFuture ?? false;

  @override
  bool get canLoadHistory => _matrixTimeline?.canRequestHistory ?? false;

  @override
  bool get isLoadingFuture => _matrixTimeline?.isRequestingFuture ?? false;

  @override
  bool get isLoadingHistory => _matrixTimeline?.isRequestingHistory ?? false;

  @override
  Future<void> loadMoreFuture() async {
    if (canLoadFuture) {
      var f = _matrixTimeline?.requestFuture();

      _loadingStatusChangedController.add(null);
      await f;
    }
  }

  @override
  void markAsRead(TimelineEvent event) async {
    if (event.status == TimelineEventStatus.synced) {
      _matrixTimeline?.setReadMarker();
    }
  }

  @override
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId) async {
    var event = await _matrixRoom.getEventById(eventId);
    if (event == null) return null;
    return _room.convertEvent(event);
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

    if (event is TimelineEventMessage) {
      return true;
    }

    if (event is TimelineEventSticker) {
      return true;
    }

    return true;
  }

  @override
  Future<void> close() async {
    _matrixTimeline?.cancelSubscriptions();
    await onEventAdded.close();
    await onChange.close();
    await onRemove.close();
  }

  @override
  bool isEventRedacted(TimelineEvent<Client> event) {
    var e = event as MatrixTimelineEvent;
    return e.event.getDisplayEvent(_matrixTimeline!).redacted;
  }
}
