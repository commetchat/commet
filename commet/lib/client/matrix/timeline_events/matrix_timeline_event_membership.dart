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
  inviteRejected,
  uninvited,
  acceptedInvite,
  ban,
  unban,
  updateDisplayName,
  updateAvatar,
  unknown,
}

enum _SenderType {
  self,
  other,
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
      Intl.message("$user changed their display name to \"$newName\"",
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

  String messageUserRetractedInvite(String sender, String user) => Intl.message(
      "$sender uninvited $user",
      desc: "Message body for when a user's invitation to a room was withdrawn",
      args: [sender, user],
      name: "messageUserRetractedInvite");

  String messageUserAcceptedInvite(String user) =>
      Intl.message("$user accepted the invitiation",
          desc: "Message body for when a user accepted an invitation to a room",
          args: [user],
          name: "messageUserAcceptedInvite");

  String messageUserBanned(String sender, String user) =>
      Intl.message("$sender banned $user",
          desc: "Message body for when a user bans another user from the room",
          args: [sender, user],
          name: "messageUserBanned");

  String messageUserUnbanned(String sender, String user) =>
      Intl.message("$sender unbanned $user",
          desc: "Message body for when a user reverts a ban of another user",
          args: [sender, user],
          name: "messageUserUnbanned");

  @override
  IconData get icon => switch (_getType()) {
        _MembershipType.join => Icons.waving_hand_rounded,
        _MembershipType.leave => Icons.subdirectory_arrow_left_rounded,
        _MembershipType.kick => Icons.subdirectory_arrow_left_rounded,
        _MembershipType.invite => Icons.person_add,
        _MembershipType.updateDisplayName => Icons.person,
        _MembershipType.updateAvatar => Icons.person,
        _MembershipType.unknown => Icons.person,
        _MembershipType.inviteRejected => Icons.person_remove,
        _MembershipType.uninvited => Icons.person_remove,
        _MembershipType.acceptedInvite => Icons.waving_hand_rounded,
        _MembershipType.ban => Icons.person_remove,
        _MembershipType.unban => Icons.shield_outlined,
      };

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  _MembershipType _getType() {
    bool wasSelf = event.stateKey == event.senderId;

    var prev = event.prevContent?["membership"];
    var curr = event.content["membership"];
    var sender = wasSelf ? _SenderType.self : _SenderType.other;

    var type = switch ([prev, curr, sender]) {
      ["join", "leave", _SenderType.other] => _MembershipType.kick,
      ["join", "leave", _SenderType.self] => _MembershipType.leave,
      ["leave", "join", _SenderType.self] => _MembershipType.join,
      ["join", "ban", _SenderType.other] => _MembershipType.ban,
      ["invite", "leave", _SenderType.other] => _MembershipType.uninvited,
      ["invite", "leave", _SenderType.self] => _MembershipType.inviteRejected,
      ["invite", "join", _SenderType.self] => _MembershipType.acceptedInvite,
      ["ban", "leave", _SenderType.other] => _MembershipType.unban,
      _ => _MembershipType.unknown,
    };

    if (type != _MembershipType.unknown) {
      return type;
    }

    if (curr == prev) {
      if (event.prevContent?["displayname"] != event.content["displayname"]) {
        return _MembershipType.updateDisplayName;
      }

      if (event.prevContent?["avatar_url"] != event.content["avatar_url"]) {
        return _MembershipType.updateAvatar;
      }
    }

    type = switch ([curr, sender]) {
      ["invite", _SenderType.other] => _MembershipType.invite,
      ["ban", _SenderType.other] => _MembershipType.ban,
      ["join", _SenderType.self] => _MembershipType.join,
      _ => _MembershipType.unknown,
    };

    return type;
  }

  @override
  String getBody({Timeline? timeline}) {
    String sender = event.senderId;

    String? prevDisplayName = event.prevContent?["displayname"] as String?;
    String? newDisplayName = event.content["displayname"] as String?;

    String memberName = newDisplayName ?? prevDisplayName ?? event.stateKey!;

    var type = _getType();

    switch (type) {
      case _MembershipType.join:
        return messagePlaceholderUserJoinedRoom(memberName);
      case _MembershipType.leave:
        return messagePlaceholderUserLeftRoom(memberName);
      case _MembershipType.kick:
        return "$memberName was kicked from the room by $sender";
      case _MembershipType.invite:
        return messagePlaceholderUserInvited(sender, memberName);
      case _MembershipType.updateDisplayName:
        if (newDisplayName != null)
          return messagePlaceholderUserUpdatedNameDetailed(
              event.stateKey!, newDisplayName);
        return messagePlaceholderUserUpdatedName(memberName);
      case _MembershipType.updateAvatar:
        return messagePlaceholderUserUpdatedAvatar(memberName);
      case _MembershipType.inviteRejected:
        return messagePlaceholderUserRejectedInvite(memberName);
      case _MembershipType.uninvited:
        return messageUserRetractedInvite(sender, memberName);
      case _MembershipType.acceptedInvite:
        return messageUserAcceptedInvite(memberName);
      case _MembershipType.ban:
        return messageUserBanned(sender, memberName);
      case _MembershipType.unban:
        return messageUserUnbanned(sender, memberName);
      case _MembershipType.unknown:
        return event.body;
    }
  }
}
