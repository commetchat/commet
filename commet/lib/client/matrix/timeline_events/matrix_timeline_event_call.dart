import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventCall extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventCall(super.event, {required super.client});

  String messageUserAnsweredCall(String user) =>
      Intl.message("$user answered the call",
          desc: "Message body for when a user answers a call",
          args: [user],
          name: "messageUserAnsweredCall");

  String messageUserHangupCall(String user) =>
      Intl.message("$user ended the call",
          desc: "Message body for when a user hangs up a call",
          args: [user],
          name: "messageUserHangupCall");

  String messageUserRejectCall(String user) =>
      Intl.message("$user rejected the call",
          desc: "Message body for when a user rejects a call",
          args: [user],
          name: "messageUserRejectCall");

  String messageUserInviteCall(String user) =>
      Intl.message("$user started a call",
          desc: "Message body for when a user starts a call",
          args: [user],
          name: "messageUserInviteCall");

  @override
  IconData get icon {
    if (event.type == matrix.EventTypes.CallAnswer ||
        event.type == matrix.EventTypes.CallInvite) {
      return Icons.call;
    }

    return Icons.call_end;
  }

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  @override
  String getBody({Timeline? timeline}) {
    var name = event.senderFromMemoryOrFallback.displayName ?? event.senderId;

    if (event.type == matrix.EventTypes.CallAnswer) {
      return messageUserAnsweredCall(name);
    }

    if (event.type == matrix.EventTypes.CallHangup) {
      return messageUserHangupCall(name);
    }

    if (event.type == matrix.EventTypes.CallReject) {
      return messageUserRejectCall(name);
    }

    if (event.type == matrix.EventTypes.CallInvite) {
      return messageUserInviteCall(name);
    }

    return event.body;
  }
}
