import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/utils/gif_search/gif_search_result.dart';
import 'package:flutter/material.dart';
import 'attachment.dart';
import 'permissions.dart';

enum RoomVisibility { public, private, invite, knock }

enum PushRule { notify, mentionsOnly, dontNotify }

abstract class Room {
  late String identifier;
  late Client client;
  final Key key = UniqueKey();

  Timeline? timeline;
  late ImageProvider? avatar;
  Iterable<String> get memberIds;

  String get displayName;

  bool get isDirectMessage;

  String? get directMessagePartnerID;

  Permissions get permissions;

  bool get isMember => false;
  bool get isE2EE;
  Color get defaultColor;
  Stream<void> get onUpdate;
  PushRule get pushRule;
  DateTime get lastEventTimestamp;

  List<Peer> get typingPeers;

  String get developerInfo;

  int get notificationCount;
  int get highlightedNotificationCount;

  int get displayNotificationCount =>
      pushRule == PushRule.notify ? notificationCount : 0;

  int get displayHighlightedNotificationCount =>
      pushRule != PushRule.dontNotify ? highlightedNotificationCount : 0;

  Room(this.identifier, this.client) {
    identifier = identifier;
    client = client;
    avatar = null;
  }

  Future<TimelineEvent?> sendMessage({
    String? message,
    TimelineEvent? inReplyTo,
    TimelineEvent? replaceEvent,
    List<ProcessedAttachment> processedAttachments,
  });

  Future<TimelineEvent?> addReaction(
      TimelineEvent reactingTo, Emoticon reaction);

  Future<void> removeReaction(TimelineEvent reactingTo, Emoticon reaction);

  Future<TimelineEvent?> sendGif(GifSearchResult gif, TimelineEvent? inReplyTo);

  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments);

  String get localId => "${client.identifier}:$identifier";

  Future<void> setDisplayName(String newName);

  @protected
  Future<void> setDisplayNameInternal(String name);

  Future<void> setPushRule(PushRule rule);

  Future<void> setTypingStatus(bool typing);

  Color getColorOfUser(String userId);

  Future<void> enableE2EE();

  TimelineEvent? get lastEvent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;
    if (other.client != client) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
