import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';

class MatrixTimelineEventPinnedMessages extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventPinnedMessages(super.event, {required super.client});

  bool isNewEventPinned() {
    if (event.prevContent?.containsKey('pinned') == true) {
      var prevList = event.prevContent!['pinned'] as List<dynamic>;
      var currList = event.content['pinned'] as List<dynamic>;

      return currList.length > prevList.length;
    } else {
      return true;
    }
  }

  @override
  IconData get icon => Icons.push_pin;

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  @override
  String getBody({Timeline? timeline}) {
    if (isNewEventPinned()) {
      return "Message pinned!";
    } else {
      return "Message unpinned!";
    }
  }
}
