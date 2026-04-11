import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/role.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/material.dart';
import 'attachment.dart';
import 'permissions.dart';

// enum RoomVisibility { public, private, invite, knock }

abstract class RoomVisibility {
  static IconData icon(RoomVisibility? visibility) {
    return switch (visibility) {
      final RoomVisibilityPublic _ => Icons.public,
      final RoomVisibilityPrivate _ => Icons.lock,
      final RoomVisibilityRestricted _ => Icons.shield,
      _ => Icons.question_mark,
    };
  }
}

class RoomVisibilityPrivate implements RoomVisibility {
  @override
  bool operator ==(Object other) {
    if (other is RoomVisibilityPrivate) return true;
    if (identical(this, other)) return true;
    return false;
  }
}

class RoomVisibilityPublic implements RoomVisibility {
  @override
  bool operator ==(Object other) {
    if (other is RoomVisibilityPublic) return true;
    if (identical(this, other)) return true;
    return false;
  }
}

class RoomVisibilityRestricted implements RoomVisibility {
  final List<String> spaces;

  @override
  bool operator ==(Object other) {
    if (other is! RoomVisibilityRestricted) return false;
    if (identical(this, other)) return true;

    return ListEquality().equals(this.spaces, other.spaces);
  }

  RoomVisibilityRestricted(this.spaces);
}

enum PushRule { notify, mentionsOnly, dontNotify }

/// The Room object should only be used for rooms which the user is a member of.
/// Rooms which the user has not joined should be represented with a RoomPreview
abstract class Room {
  String get identifier;
  Client get client;
  final Key key = UniqueKey();

  /// Gets the room timeline
  Timeline? get timeline;

  /// Gets the room's avatar
  ImageProvider? get avatar;

  String? get avatarId;

  /// Returns a list of member IDs
  Iterable<String> get memberIds;

  /// Returns the localized display name
  String get displayName;

  String? get topic;

  /// The permissions of the room
  Permissions get permissions;

  /// Returns true if the room is secured by end to end encryption
  bool get isE2EE;

  /// Returns true if the room has a tombstone state
  bool get isTombstoned;

  /// Returns the replacement room ID when tombstoned
  String? get tombstoneReplacementRoomId;

  /// Returns the tombstone body message when available
  String? get tombstoneBody;

  bool get isSpecialRoomType;

  IconData get icon {
    var dm = client.getComponent<DirectMessagesComponent>();
    if (dm?.isRoomDirectMessage(this) == true) {
      return Icons.alternate_email_rounded;
    }

    var voip = getComponent<VoipRoomComponent>();
    if (voip != null) {
      return Icons.volume_up;
    }

    var photos = getComponent<PhotoAlbumRoom>();
    if (photos != null) {
      return Icons.photo;
    }

    var calendar = getComponent<CalendarRoom>();
    if (calendar?.isCalendarRoom == true) {
      return Icons.calendar_month;
    }

    return Icons.tag;
  }

  bool get shouldPreviewMedia;

  /// Returns a color to use for the room's avatar
  Color get defaultColor;

  /// Stream which is called when the room state updates
  Stream<void> get onUpdate;

  /// Rule for push notifications for this room
  PushRule get pushRule;

  /// Gets the time of the last known event
  DateTime get lastEventTimestamp;

  /// Debug info for developers
  String get developerInfo;

  /// The number of notifications in this room
  int get notificationCount;

  /// The number of highlighted / important notifications in this room
  int get highlightedNotificationCount;

  /// The number of notifications to display
  int get displayNotificationCount =>
      pushRule == PushRule.notify ? notificationCount : 0;

  /// The number of highlighted notifications to display
  int get displayHighlightedNotificationCount =>
      pushRule != PushRule.dontNotify ? highlightedNotificationCount : 0;

  RoomVisibility get visibility;

  /// Send a message in this room
  Future<TimelineEvent?> sendMessage({
    String? message,
    TimelineEvent? inReplyTo,
    TimelineEvent? replaceEvent,
    List<ProcessedAttachment> processedAttachments,
  });

  Future<void> cancelSend(TimelineEvent event);

  Future<void> retrySend(TimelineEvent event);

  /// Add an emoticon reaction to a message
  Future<TimelineEvent?> addReaction(
    TimelineEvent reactingTo,
    Emoticon reaction,
  );

  /// Remove an emoticon reaction to a message
  Future<void> removeReaction(TimelineEvent reactingTo, Emoticon reaction);

  /// Processes files before sending as attachment
  Future<List<ProcessedAttachment>> processAttachments(
    List<PendingFileAttachment> attachments,
  );

  List<Member> membersList();

  Future<List<Member>> fetchMembersList({bool cache = false});

  List<(Member, Role)> importantMembers();

  Role getMemberRole(String identifier);

  bool get isMembersListComplete;

  /// A locally unique identifier, to distinguish between rooms when two or more accounts in this app are in the same room
  String get localId => "${client.identifier}:$identifier";

  /// Update the display name of this room
  Future<void> setDisplayName(String newName);

  Future<void> setRoomAvatar(Uint8List bytes, String? mimeType);

  /// Set a notification push rule
  Future<void> setPushRule(PushRule rule);

  Future<void> setVisibility(RoomVisibility visibility);

  /// Gets the color of a user based on their ID
  Color getColorOfUser(String userId);

  /// Gets the timeline of a room, loading it if not yet loaded
  Future<Timeline> getTimeline({String contextEventId});

  /// Enables end to end encryption in a room
  Future<void> enableE2EE();

  Future<void> close();

  // Returns true if a notification should be sent for a given event
  bool shouldNotify(TimelineEvent event);

  /// The last known event in the room timeline
  TimelineEvent? get lastEvent;

  T? getComponent<T extends RoomComponent>();

  List<T> getAllComponents<T extends RoomComponent<Client, Room>>();

  Future<ImageProvider?> getShortcutImage();

  Future<TimelineEvent?> getEvent(String eventId);

  Future<void> kickUser(String id);

  Future<void> banUser(String id);

  Member getMemberOrFallback(String id);

  Member? getMember(String id);

  Future<Member> fetchMember(String id);

  List<Role> get availableRoles;

  Future<void> setMemberRole(String id, Role role);

  Future<void> setTopic(String topic);

  Future<void> markAsRead();

  @override
  bool operator ==(Object other) {
    if (other is! Room) return false;
    if (other.client != client) return false;
    if (identical(this, other)) return true;
    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
