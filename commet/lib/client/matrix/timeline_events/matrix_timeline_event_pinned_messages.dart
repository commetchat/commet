import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventPinnedMessages extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventPinnedMessages(super.event, {required super.client});

  String messageUserPinnedEvent(String user) => Intl.message(
      "$user pinned a message!",
      desc:
          "Message body for when a user adds an event to the room's pinned messages",
      args: [user],
      name: "messageUserPinnedEvent");

  String messageUserUnpinnedEvent(String user) => Intl.message(
      "$user unpinned a message",
      desc:
          "Message body for when a user removes an event from the room's pinned messages",
      args: [user],
      name: "messageUserUnpinnedEvent");

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
    var name = event.senderFromMemoryOrFallback.displayName ?? event.senderId;

    if (isNewEventPinned()) {
      return messageUserPinnedEvent(name);
    } else {
      return messageUserUnpinnedEvent(name);
    }
  }
}
