import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixThreadTimeline implements Timeline {
  @override
  Client client;

  @override
  late List<TimelineEvent> events;

  @override
  Room room;

  MatrixTimeline mainRoomTimeline;

  ThreadsComponent component;

  String threadRootId;

  @override
  StreamController<int> onChange = StreamController.broadcast();

  @override
  StreamController<int> onEventAdded = StreamController.broadcast();

  @override
  StreamController<int> onRemove = StreamController.broadcast();

  final StreamController<void> _loadingStatusChangedController =
      StreamController.broadcast();

  @override
  Stream<void> get onLoadingStatusChanged =>
      _loadingStatusChangedController.stream;

  late List<StreamSubscription> subs;

  String? nextBatch;
  bool finished = false;

  Future? nextChunkRequest;

  @override
  bool get canLoadFuture => false;

  @override
  bool get canLoadHistory => nextBatch != null && nextChunkRequest != null;

  @override
  bool get isLoadingFuture => false;

  @override
  bool isLoadingHistory = false;

  MatrixThreadTimeline({
    required this.client,
    required this.room,
    required this.threadRootId,
    required this.mainRoomTimeline,
    required this.component,
    this.nextBatch,
  }) {
    subs = [
      mainRoomTimeline.onEventAdded.stream.listen(onMainTimelineEventAdded),
      mainRoomTimeline.onChange.stream.listen(onMainTimelineEventChanged),
      mainRoomTimeline.onRemove.stream.listen(onMainTimelineEventRemoved),
    ];

    events = List.empty(growable: true);
  }

  Future<List<TimelineEvent>> getThreadEvents(
      {int limit = 20, String? nextBatch}) async {
    var client = this.client as MatrixClient;
    var room = this.room as MatrixRoom;

    var mx = client.getMatrixClient();
    var data = await mx.request(matrix.RequestType.GET,
        "/client/unstable/rooms/${room.identifier}/relations/$threadRootId/m.thread",
        query: {
          "limit": limit.toString(),
          if (nextBatch != null) "from": nextBatch
        });

    var chunk = List<Map<String, dynamic>>.from(data["chunk"] as Iterable);

    var mxevents =
        chunk.map((e) => matrix.Event.fromJson(e, room.matrixRoom)).toList();

    for (var i = 0; i < mxevents.length; i++) {
      var event = mxevents[i];

      if (event.type == "m.room.encrypted") {
        var decrypted =
            await mx.encryption?.decryptRoomEvent(room.identifier, event);
        if (decrypted != null) {
          mxevents[i] = decrypted;
        }
      }
    }

    for (var event in mxevents) {
      mainRoomTimeline.matrixTimeline?.addAggregatedEvent(event);
    }

    var convertedEvents = mxevents
        .map((e) =>
            room.convertEvent(e, timeline: mainRoomTimeline.matrixTimeline))
        .toList();

    this.nextBatch = data["next_batch"] as String?;

    if (this.nextBatch == null) {
      finished = true;
      var root = data["original_event"] as Map<String, dynamic>?;
      if (root != null) {
        var matrixEvent = matrix.Event.fromJson(root, room.matrixRoom);
        if (matrixEvent.type == "m.room.encrypted") {
          var decrypted = await mx.encryption
              ?.decryptRoomEvent(room.identifier, matrixEvent);
          if (decrypted != null) {
            matrixEvent = decrypted;
          }
        }
        var event = room.convertEvent(matrixEvent);
        convertedEvents.add(event);
      }
    }

    return convertedEvents;
  }

  @override
  bool canDeleteEvent(TimelineEvent event) {
    return mainRoomTimeline.canDeleteEvent(event);
  }

  @override
  Future<void> close() async {
    for (var sub in subs) {
      sub.cancel();
    }
  }

  @override
  void deleteEvent(TimelineEvent event) {
    mainRoomTimeline.deleteEvent(event);
  }

  @override
  Future<TimelineEvent?> fetchEventById(String eventId) {
    return mainRoomTimeline.fetchEventById(eventId);
  }

  @override
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId) {
    return mainRoomTimeline.fetchEventByIdInternal(eventId);
  }

  @override
  bool hasEvent(String eventId) {
    return events.any((element) => element.eventId == eventId);
  }

  @override
  void insertEvent(int index, TimelineEvent event) {}

  @override
  Future<void> loadMoreHistory() async {
    if (finished) {
      return;
    }

    if (nextChunkRequest != null) {
      return;
    }

    isLoadingHistory = true;

    nextChunkRequest = getThreadEvents(nextBatch: nextBatch);
    var nextEvents = await nextChunkRequest;

    nextChunkRequest = null;

    for (var event in nextEvents) {
      events.add(event);
      onEventAdded.add(events.length - 1);
    }

    isLoadingHistory = false;
  }

  @override
  Future<void> loadMoreFuture() {
    throw UnimplementedError();
  }

  @override
  void markAsRead(TimelineEvent event) {}

  @override
  void notifyChanged(int index) {}

  @override
  TimelineEvent? tryGetEvent(String eventId) {
    return mainRoomTimeline.tryGetEvent(eventId);
  }

  bool isEventInThisThread(TimelineEvent event) {
    if (event is! MatrixTimelineEvent) {
      return false;
    }

    if (event.eventId == threadRootId) {
      return true;
    }

    var mxEvent = event.event;
    var relation = mxEvent.content["m.relates_to"];
    if (relation == null) {
      return false;
    }

    if (relation is! Map<String, dynamic>) {
      return false;
    }

    if (relation["rel_type"] != matrix.RelationshipTypes.thread) {
      return false;
    }

    if (relation["event_id"] == threadRootId) {
      return true;
    }

    var reply = relation["m.in_reply_to"] as Map<String, dynamic>?;

    if (reply == null) {
      return false;
    }

    var replyingEventID = reply["event_id"];

    if (replyingEventID == threadRootId) {
      return true;
    }

    var replyingEvent = mainRoomTimeline.tryGetEvent(replyingEventID);
    if (replyingEvent != null) {
      return isEventInThisThread(replyingEvent as MatrixTimelineEvent);
    }

    return false;
  }

  void onMainTimelineEventAdded(int index) {
    var event = mainRoomTimeline.events[index];

    if (!isEventInThisThread(event)) {
      return;
    }

    if (index == 0) {
      events.insert(0, event);
      onEventAdded.add(0);
    } else {
      // Theres gotta be a smarter way of doing this but whatever
      var copy = List<TimelineEvent>.from(mainRoomTimeline.events);
      copy.removeWhere((element) => !isEventInThisThread(element));

      var newIndex = copy.indexOf(event);
      events.insert(newIndex, event);
      onEventAdded.add(newIndex);
    }
  }

  void onMainTimelineEventChanged(int index) {
    var event = mainRoomTimeline.events[index];
    if (isEventInThisThread(event)) {
      var index =
          events.indexWhere((element) => element.eventId == event.eventId);

      events[index] = event;
      if (index != -1) {
        onChange.add(index);
      }
    }
  }

  void onMainTimelineEventRemoved(int index) {
    var event = mainRoomTimeline.events[index];
    if (isEventInThisThread(event)) {
      var index =
          events.indexWhere((element) => element.eventId == event.eventId);

      events.removeAt(index);

      if (index != -1) {
        onRemove.add(index);
      }
    }
  }

  @override
  bool isEventRedacted(TimelineEvent<Client> event) {
    var e = event as MatrixTimelineEvent;
    return e.event.getDisplayEvent(mainRoomTimeline.matrixTimeline!).redacted;
  }
}
