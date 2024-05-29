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
    matrix.Timeline? tl;

    if (timeline is MatrixTimeline) {
      tl = timeline.matrixTimeline;
    }

    if (timeline is MatrixThreadTimeline) {
      tl = timeline.mainRoomTimeline.matrixTimeline;
    }

    if (tl == null) {
      return false;
    }

    if (event is! MatrixTimelineEvent) {
      return false;
    }

    return event.event.hasAggregatedEvents(tl, matrix.RelationshipTypes.thread);
  }

  @override
  TimelineEvent? getFirstReplyToThread(TimelineEvent event, Timeline timeline) {
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

    if (event is! MatrixTimelineEvent) {
      return null;
    }

    var events =
        event.event.aggregatedEvents(tl, matrix.RelationshipTypes.thread);

    var firstEvent = events.firstOrNull;
    if (firstEvent == null) {
      return null;
    }

    return MatrixTimelineEvent(firstEvent, client.getMatrixClient());
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
  Future<TimelineEvent?> sendMessage(
      {required String threadRootEventId,
      required Room room,
      String? message,
      TimelineEvent? inReplyTo,
      TimelineEvent? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) async {
    if (room is! MatrixRoom) {
      return null;
    }

    var newMessage = await room.sendMessage(
        message: message,
        inReplyTo: inReplyTo,
        replaceEvent: replaceEvent,
        processedAttachments: processedAttachments,
        threadRootEventId: threadRootEventId) as MatrixTimelineEvent?;

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
