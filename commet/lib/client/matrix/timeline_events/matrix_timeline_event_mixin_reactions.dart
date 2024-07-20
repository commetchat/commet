import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/threads/matrix_thread_timeline.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_reactions.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';

import 'package:matrix/matrix.dart' as matrix;

mixin MatrixTimelineEventReactions on MatrixTimelineEventBase
    implements TimelineEventFeatureReactions {
  @override
  bool hasReactions(Timeline timeline) {
    var matrixEvent = event;
    MatrixTimeline tl;

    if (timeline is MatrixThreadTimeline) {
      tl = timeline.mainRoomTimeline;
    } else {
      tl = timeline as MatrixTimeline;
    }

    var mxTimeline = tl.matrixTimeline!;

    return matrixEvent.hasAggregatedEvents(
        mxTimeline, matrix.RelationshipTypes.reaction);
  }

  @override
  Map<Emoticon, Set<String>> getReactions(Timeline timeline) {
    var matrixEvent = event;
    MatrixTimeline tl;

    if (timeline is MatrixThreadTimeline) {
      tl = timeline.mainRoomTimeline;
    } else {
      tl = timeline as MatrixTimeline;
    }
    var mxTimeline = tl.matrixTimeline!;
    if (!matrixEvent.hasAggregatedEvents(
        mxTimeline, matrix.RelationshipTypes.reaction)) return {};

    var reactions = <Emoticon, Set<String>>{};

    var events = matrixEvent
        .aggregatedEvents(mxTimeline, matrix.RelationshipTypes.reaction)
        .toList();

    events.sort((eventA, eventB) =>
        eventA.originServerTs.compareTo(eventB.originServerTs));

    for (var event in events) {
      var emoji = getEmoticonFromReactionEvent(event, mxTimeline);
      if (!reactions.containsKey(emoji)) reactions[emoji] = {};

      if (reactions.containsKey(emoji)) {
        reactions[emoji]!.add(event.senderId);
      }
    }

    return reactions;
  }

  Emoticon getEmoticonFromReactionEvent(
      matrix.Event event, matrix.Timeline timeline) {
    var content = event.content["m.relates_to"] as Map<String, Object?>;
    var key = content['key'] as String;

    if (key.startsWith("mxc://")) {
      return MatrixEmoticon(Uri.parse(key), timeline.room.client,
          shortcode: event.content.tryGet("shortcode") ?? "");
    }

    return UnicodeEmoticon(key, shortcode: content['shortcode'] as String?);
  }
}
