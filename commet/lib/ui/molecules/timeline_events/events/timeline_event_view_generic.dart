import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart' as m;

import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:tiamat/atoms/avatar.dart';

class TimelineEventViewGeneric extends StatefulWidget {
  const TimelineEventViewGeneric(
      {required this.timeline, required this.initialIndex, super.key});
  final Timeline timeline;
  final int initialIndex;
  @override
  State<TimelineEventViewGeneric> createState() =>
      _TimelineEventViewGenericState();
}

class _TimelineEventViewGenericState extends State<TimelineEventViewGeneric>
    implements TimelineEventViewWidget {
  String? text;
  IconData? icon;
  ImageProvider? senderAvatar;

  String messagePlaceholderSticker(String user) =>
      Intl.message("$user sent a sticker",
          desc: "Message body for when a user sends a sticker",
          args: [user],
          name: "messagePlaceholderSticker");

  String messagePlaceholderUserCreatedRoom(String user) =>
      Intl.message("$user created the room!",
          desc: "Message body for when a user created the room",
          args: [user],
          name: "messagePlaceholderUserCreatedRoom");

  String get errorMessageFailedToSend => Intl.message("Failed to send",
      desc:
          "Text that is placed below a message when the message fails to send",
      name: "errorMessageFailedToSend");

  @override
  void initState() {
    setStateFromindex(widget.initialIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Container();
    }

    return m.Material(
      color: m.Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 0, 8, 0),
                    child: Icon(
                      icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                if (senderAvatar != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 0, 8, 0),
                    child: Avatar(
                      image: senderAvatar,
                      radius: 10,
                    ),
                  ),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(child: tiamat.Text.labelLow(text!)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void update(int newIndex) {
    setStateFromindex(newIndex);
  }

  void setStateFromindex(int index) {
    var event = widget.timeline.events[index];

    if (event is! TimelineEventGeneric) {
      text = event.plainTextBody;
      icon = Icons.question_mark;
      return;
    }

    text = event.getBody(timeline: widget.timeline);
    icon = event.icon;

    var sender = widget.timeline.room.getMemberOrFallback(event.senderId);
    if (event.showSenderAvatar) {
      senderAvatar = sender.avatar;
    }
  }
}
