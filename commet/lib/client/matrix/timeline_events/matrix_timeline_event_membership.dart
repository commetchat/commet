import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _MembershipType {
  join,
  leave,
  kick,
  invite,
  updateDisplayName,
  updateAvatar,
  unknown,
}

class MatrixTimelineEventMembership extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventMembership(super.event, {required super.client});

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

  String messagePlaceholderUserUpdatedNameDetailed(
          String user, String newName) =>
      Intl.message("$user changed their display name to $newName",
          desc: "Message body for when a user updates their display name",
          args: [user, newName],
          name: "messagePlaceholderUserUpdatedNameDetailed");

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

  @override
  IconData get icon => switch (_getType()) {
        _MembershipType.join => Icons.waving_hand_rounded,
        _MembershipType.leave => Icons.subdirectory_arrow_left_rounded,
        _MembershipType.kick => Icons.subdirectory_arrow_left_rounded,
        _MembershipType.invite => Icons.person_add,
        _MembershipType.updateDisplayName => Icons.person,
        _MembershipType.updateAvatar => Icons.person,
        _MembershipType.unknown => Icons.person,
      };

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  _MembershipType _getType() {
    bool wasSelf = event.stateKey == event.senderId;

    if (event.prevContent?["membership"] != event.content["membership"]) {
      switch (event.content["membership"]) {
        case "join":
          return _MembershipType.join;
        case "leave":
          return wasSelf ? _MembershipType.leave : _MembershipType.kick;
        case "invite":
          return _MembershipType.invite;
      }
    }

    if (event.prevContent?["displayname"] != event.content["displayname"]) {
      return _MembershipType.updateDisplayName;
    }

    if (event.prevContent?["avatar_url"] != event.content["avatar_url"]) {
      return _MembershipType.updateAvatar;
    }

    return _MembershipType.unknown;
  }

  @override
  String getBody({Timeline? timeline}) {
    String sender = event.senderId;

    String? prevDisplayName = event.prevContent?["displayname"] as String?;
    String? newDisplayName = event.content["displayname"] as String?;

    String memberName = newDisplayName ?? prevDisplayName ?? event.senderId;

    var type = _getType();

    switch (type) {
      case _MembershipType.join:
        return messagePlaceholderUserJoinedRoom(memberName);
      case _MembershipType.leave:
        return messagePlaceholderUserLeftRoom(memberName);
      case _MembershipType.kick:
        return "$memberName was kicked from the room by $sender";
      case _MembershipType.invite:
        return messagePlaceholderUserInvited(memberName, sender);
      case _MembershipType.updateDisplayName:
        if (newDisplayName != null)
          return messagePlaceholderUserUpdatedNameDetailed(
              prevDisplayName ?? event.senderId, newDisplayName);
        return messagePlaceholderUserUpdatedName(memberName);
      case _MembershipType.updateAvatar:
        return messagePlaceholderUserUpdatedAvatar(memberName);
      case _MembershipType.unknown:
        return event.body;
    }
  }
}
