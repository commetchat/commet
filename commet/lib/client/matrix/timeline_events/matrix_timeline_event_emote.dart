import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_mixin_per_message_profile.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_emote.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventEmote extends MatrixTimelineEvent
    with MatrixTimelineEventPerMessageProfile
    implements TimelineEventEmote, TimelineEventGeneric {
  MatrixTimelineEventEmote(super.event, {required super.client});

  String messageUserEmote(String user, String emote) =>
      Intl.message("*$user $emote",
          desc: "Message to display when a user does a custom emote (/me)",
          args: [user, emote],
          name: "messageUserEmote");

  String messageUserEmoteViaProfile(String user, String emote, String sender) =>
      Intl.message("*$user $emote (via $sender)",
          desc:
              "Message to display when a user does a custom emote (/me) with a per message profile",
          args: [user, emote, sender],
          name: "messageUserEmoteViaProfile");

  @override
  String getBody({Timeline? timeline}) {
    String? sender = event.senderId.localpart;

    if (timeline != null) {
      sender = timeline.room.getMemberOrFallback(event.senderId).displayName;
    }

    var body = stripFallback(event.body, timeline: timeline);

    var profile = getPerMessageProfile(timeline: timeline);
    if (profile?.hasDisplayName == true && sender != null) {
      return messageUserEmoteViaProfile(profile!.displayName!, body, sender);
    }

    if (sender != null) {
      return messageUserEmote(sender, body);
    }

    return body;
  }

  @override
  IconData? get icon => null;

  @override
  bool get showSenderAvatar => true;
}
