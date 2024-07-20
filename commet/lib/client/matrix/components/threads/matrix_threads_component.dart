import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/matrix/components/threads/matrix_thread_timeline.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixThreadsComponent implements ThreadsComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixThreadsComponent(this.client);

  @override
  bool isEventInResponseToThread(TimelineEventBase event, Timeline timeline) {
    if (event is! MatrixTimelineEventBase) {
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

    if (relation["rel_type"] == matrix.RelationshipTypes.thread) {
      return true;
    }

    if (relation.containsKey("m.in_reply_to")) {
      var replyingEventID = relation["m.in_reply_to"]["event_id"];
      var replyingEvent = timeline.tryGetEvent(replyingEventID);
      if (replyingEvent != null) {
        return isEventInResponseToThread(replyingEvent, timeline);
      }
    }

    return false;
  }

  @override
  bool isHeadOfThread(TimelineEventBase event, Timeline timeline) {
    matrix.Timeline? tl;

    if (timeline is MatrixTimeline) {
      tl = timeline.matrixTimeline;
    }

    if (timeline is MatrixThreadTimeline) {
      if (event.eventId == timeline.threadRootId) {
        return true;
      }
      tl = timeline.mainRoomTimeline.matrixTimeline;
    }

    if (tl == null) {
      return false;
    }

    if (event is! MatrixTimelineEventBase) {
      return false;
    }

    if (event.event.unsigned?.containsKey("m.relations") == true) {
      var relations =
          event.event.unsigned!["m.relations"] as Map<String, dynamic>;
      if (relations.containsKey("m.thread")) {
        return true;
      }
    }

    return event.event.hasAggregatedEvents(tl, matrix.RelationshipTypes.thread);
  }

  @override
  TimelineEventBase? getFirstReplyToThread(
      TimelineEventBase event, Timeline timeline) {
    matrix.Timeline? tl;

    if (timeline is MatrixTimeline) {
      tl = timeline.matrixTimeline;
    }

    if (timeline is MatrixThreadTimeline) {
      tl = timeline.mainRoomTimeline.matrixTimeline;
    }

    if (tl == null) {
      return null;
    }

    if (event is! MatrixTimelineEventBase) {
      return null;
    }

    if (event.event.unsigned?.containsKey("m.relations") == true) {
      var relations =
          event.event.unsigned!["m.relations"] as Map<String, dynamic>;
      if (relations.containsKey("m.thread")) {
        var info = relations["m.thread"] as Map<String, dynamic>;
        if (info.containsKey("latest_event") == true) {
          var matrixEvent =
              matrix.Event.fromJson(info["latest_event"], tl.room);

          tl.addAggregatedEvent(matrixEvent);

          return (timeline.room as MatrixRoom).convertEvent(matrixEvent);
        }
      }
    }

    var events =
        event.event.aggregatedEvents(tl, matrix.RelationshipTypes.thread);

    var firstEvent = events.firstOrNull;
    if (firstEvent == null) {
      return null;
    }
    return (timeline.room as MatrixRoom).convertEvent(firstEvent);
  }

  @override
  Future<Timeline?> getThreadTimeline(
      {required Timeline roomTimeline,
      required String threadRootEventId}) async {
    if (roomTimeline is! MatrixTimeline) {
      return null;
    }

    var client = roomTimeline.client as MatrixClient;
    var room = (roomTimeline.room as MatrixRoom);

    var timeline = MatrixThreadTimeline(
        client: client,
        room: room,
        threadRootId: threadRootEventId,
        mainRoomTimeline: roomTimeline,
        component: this);

    await timeline.loadMoreHistory();

    return timeline;
  }

  @override
  Future<TimelineEventBase?> sendMessage(
      {required String threadRootEventId,
      required Room room,
      String? message,
      TimelineEventBase? inReplyTo,
      TimelineEventBase? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) async {
    if (room is! MatrixRoom) {
      return null;
    }

    var newMessage = await room.sendMessage(
        message: message,
        inReplyTo: inReplyTo,
        replaceEvent: replaceEvent,
        processedAttachments: processedAttachments,
        threadRootEventId: threadRootEventId) as MatrixTimelineEventBase?;

    if (room.timeline != null) {
      var index = room.timeline!.events
          .indexWhere((element) => element.eventId == threadRootEventId);

      (room.timeline as MatrixTimeline)
          .matrixTimeline!
          .addAggregatedEvent(newMessage!.event);

      if (index != -1) {
        room.timeline!.notifyChanged(index);
      }
    }

    return null;
  }
}
