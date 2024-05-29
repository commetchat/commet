import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/matrix/matrix_timeline_event.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixThreadTimeline implements Timeline {
  @override
  Client client;

  @override
  late List<TimelineEvent> events;

  @override
  Room room;

  Timeline mainRoomTimeline;

  ThreadsComponent component;

  String threadRootId;

  @override
  StreamController<int> onChange = StreamController.broadcast();

  @override
  StreamController<int> onEventAdded = StreamController.broadcast();

  @override
  StreamController<int> onRemove = StreamController.broadcast();

  MatrixThreadTimeline({
    required this.client,
    required this.room,
    required this.threadRootId,
    required List<MatrixTimelineEvent> events,
    required this.mainRoomTimeline,
    required this.component,
  }) {
    this.events = List.from(events);

    mainRoomTimeline.onEventAdded.stream.listen(onMainTimelineEventAdded);
    mainRoomTimeline.onChange.stream.listen(onMainTimelineEventChanged);
  }

  @override
  bool canDeleteEvent(TimelineEvent event) {
    return mainRoomTimeline.canDeleteEvent(event);
  }

  @override
  Future<void> close() async {}

  @override
  void deleteEvent(TimelineEvent event) {
    return mainRoomTimeline.deleteEvent(event);
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
  Future<void> loadMoreHistory() async {}

  @override
  void markAsRead(TimelineEvent event) {}

  @override
  void notifyChanged(int index) {
    // TODO: implement notifyChanged
  }

  @override
  // TODO: implement receipts
  List<String>? get receipts => throw UnimplementedError();

  @override
  TimelineEvent? tryGetEvent(String eventId) {
    return mainRoomTimeline.tryGetEvent(eventId);
  }

  bool isEventInThisThread(TimelineEvent event) {
    if (event is! MatrixTimelineEvent) {
      return false;
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
    print("Main timeline got a new event!");
    if (index == 0) {
      var event = mainRoomTimeline.events[index];

      if (isEventInThisThread(event)) {
        events.insert(0, event);
        onEventAdded.add(0);
      }
    }
  }

  void onMainTimelineEventChanged(int index) {
    print("An event from main timeline was changed:");

    var event = mainRoomTimeline.events[index];
    print(event.eventId);
    if (isEventInThisThread(event)) {
      var index =
          events.indexWhere((element) => element.eventId == event.eventId);

      events[index] = event;
      if (index != -1) {
        onChange.add(index);
      }
    }
  }
}
