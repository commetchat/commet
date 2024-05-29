import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/matrix/components/threads/matrix_thread_timeline.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/matrix_timeline_event.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixThreadsComponent implements ThreadsComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixThreadsComponent(this.client);

  @override
  bool isEventInResponseToThread(TimelineEvent event, Timeline timeline) {
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

    if (relation["rel_type"] == matrix.RelationshipTypes.thread) {
      return true;
    }

    var replyingEventID = relation["m.in_reply_to"]["event_id"];
    var replyingEvent = timeline.tryGetEvent(replyingEventID);
    if (replyingEvent != null) {
      return isEventInResponseToThread(replyingEvent, timeline);
    }
    return false;
  }

  @override
  bool isHeadOfThread(TimelineEvent event, Timeline timeline) {
    if (timeline is! MatrixTimeline) {
      return false;
    }
    if (event is! MatrixTimelineEvent) {
      return false;
    }

    if (timeline.matrixTimeline == null) {
      return false;
    }

    return event.event.hasAggregatedEvents(
        timeline.matrixTimeline!, matrix.RelationshipTypes.thread);
  }

  @override
  Future<Timeline?> getThreadTimeline(
      {required Timeline roomTimeline,
      required String threadRootEventId}) async {
    if (roomTimeline is! MatrixTimeline) {
      return null;
    }

    var client = roomTimeline.client as MatrixClient;
    var mx = client.getMatrixClient();
    var room = (roomTimeline.room as MatrixRoom);
    var relatedEvents = await mx.request(matrix.RequestType.GET,
        "/client/unstable/rooms/${room.identifier}/relations/$threadRootEventId/m.thread");

    var chunk =
        List<Map<String, dynamic>>.from(relatedEvents["chunk"] as Iterable);

    var mxevents = chunk.map((e) => matrix.Event.fromJson(e, room.matrixRoom));

    var events = mxevents.map((e) => MatrixTimelineEvent(e, mx)).toList();

    var rootEvent =
        await roomTimeline.matrixTimeline!.getEventById(threadRootEventId);

    if (rootEvent != null) {
      events.add(MatrixTimelineEvent(rootEvent, mx));
    }

    var timeline = MatrixThreadTimeline(
        client: client,
        room: room,
        events: events,
        threadRootId: threadRootEventId,
        mainRoomTimeline: roomTimeline,
        component: this);
    return timeline;
  }

  @override
  Future<TimelineEvent?> sendMessage(
      {required String threadRootEventId,
      required Room room,
      String? message,
      TimelineEvent? inReplyTo,
      TimelineEvent? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) async {
    print("Sending message in thread :)");

    if (room is! MatrixRoom) {
      return null;
    }

    room.sendMessage(
        message: message,
        inReplyTo: inReplyTo,
        replaceEvent: replaceEvent,
        processedAttachments: processedAttachments,
        threadRootEventId: threadRootEventId);

    return null;
  }
}
