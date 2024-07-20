import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_emote.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventEmote extends MatrixTimelineEvent
    implements TimelineEventEmote, TimelineEventGeneric {
  MatrixTimelineEventEmote(super.event, {required super.client});

  String messageUserEmote(String user, String emote) =>
      Intl.message("*$user $emote",
          desc: "Message to display when a user does a custom emote (/me)",
          args: [user, emote],
          name: "messageUserEmote");

  @override
  String getBody({Timeline? timeline}) {
    String? sender = event.senderId.localpart;

    if (timeline != null) {
      sender = timeline.room.getMemberOrFallback(event.senderId).displayName;
    }

    if (sender != null) {
      return messageUserEmote(sender, event.body);
    }

    return event.body;
  }

  @override
  IconData? get icon => null;

  @override
  bool get showSenderAvatar => true;
}
