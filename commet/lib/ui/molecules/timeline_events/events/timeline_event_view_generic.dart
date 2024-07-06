import 'package:commet/client/timeline.dart';
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
  late String? text;
  late IconData? icon;
  late ImageProvider? senderAvatar;

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

  String messagePlaceholderUserJoinedRoom(String user) =>
      Intl.message("$user joined the room!",
          desc: "Message body for when a user joins the room",
          args: [user],
          name: "messagePlaceholderUserJoinedRoom");

  String messagePlaceholderUserLeftRoom(String user) =>
      Intl.message("$user left the room",
          desc: "Message body for when a user leaves the room",
          args: [user],
          name: "messagePlaceholderUserLeftRoom");

  String messagePlaceholderUserUpdatedAvatar(String user) =>
      Intl.message("$user updated their avatar",
          desc: "Message body for when a user updates their avatar",
          args: [user],
          name: "messagePlaceholderUserUpdatedAvatar");

  String messagePlaceholderUserUpdatedName(String user) =>
      Intl.message("$user updated their display name",
          desc: "Message body for when a user updates their display name",
          args: [user],
          name: "messagePlaceholderUserUpdatedName");

  String messagePlaceholderUserInvited(String sender, String invitedUser) =>
      Intl.message("$sender invited $invitedUser",
          desc: "Message body for when a user invites another user to the room",
          args: [sender, invitedUser],
          name: "messagePlaceholderUserInvited");

  String messagePlaceholderUserRejectedInvite(String user) =>
      Intl.message("$user rejected the invitation",
          desc: "Message body for when a user rejected an invitation to a room",
          args: [user],
          name: "messagePlaceholderUserRejectedInvite");

  String messageUserEmote(String user, String emote) =>
      Intl.message("*$user $emote",
          desc: "Message to display when a user does a custom emote (/me)",
          args: [user, emote],
          name: "messageUserEmote");

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
    var sender = widget.timeline.room.getMemberOrFallback(event.senderId);
    var displayName = sender.displayName;

    if ([EventType.emote].contains(event.type)) {
      senderAvatar = sender.avatar;
    } else {
      senderAvatar = null;
    }

    text = switch (event.type) {
      EventType.roomCreated => messagePlaceholderUserCreatedRoom(displayName),
      EventType.memberJoined => messagePlaceholderUserJoinedRoom(displayName),
      EventType.memberLeft => messagePlaceholderUserLeftRoom(displayName),
      EventType.memberAvatar =>
        messagePlaceholderUserUpdatedAvatar(displayName),
      EventType.memberDisplayName =>
        messagePlaceholderUserUpdatedName(displayName),
      EventType.memberInvited =>
        messagePlaceholderUserInvited(displayName, event.stateKey!),
      EventType.memberInvitationRejected =>
        messagePlaceholderUserRejectedInvite(displayName),
      EventType.emote => messageUserEmote(displayName, event.body ?? ""),
      _ => "$displayName: ${event.body}"
    };

    icon = switch (event.type) {
      EventType.roomCreated => m.Icons.room_preferences_outlined,
      EventType.memberJoined => m.Icons.waving_hand_rounded,
      EventType.memberLeft => m.Icons.subdirectory_arrow_left_rounded,
      EventType.memberAvatar => m.Icons.person,
      EventType.memberDisplayName => m.Icons.edit,
      EventType.memberInvited => m.Icons.person_add,
      EventType.memberInvitationRejected =>
        m.Icons.subdirectory_arrow_left_rounded,
      _ => null
    };
  }
}
