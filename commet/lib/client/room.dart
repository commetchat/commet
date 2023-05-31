import 'dart:async';
import 'package:commet/client/client.dart';
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
  Iterable<Peer> get members;
  late String displayName;
  late bool isDirectMessage;
  late String? directMessagePartnerID;
  late Permissions permissions;
  bool get isMember => false;
  bool get isE2EE;
  StreamController<void> onUpdate = StreamController.broadcast();
  PushRule get pushRule;

  List<Peer> get typingPeers;

  int get notificationCount;
  int get highlightedNotificationCount;

  int get displayNotificationCount =>
      pushRule == PushRule.notify ? notificationCount : 0;

  int get displayHighlightedNotificationCount =>
      pushRule != PushRule.dontNotify ? highlightedNotificationCount : 0;

  Future<TimelineEvent?> sendMessage({
    String? message,
    TimelineEvent? inReplyTo,
    TimelineEvent? replaceEvent,
    List<ProcessedAttachment> processedAttachments,
  });

  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments);

  String get localId => "${client.identifier}:$identifier";

  Room(this.identifier, this.client) {
    identifier = identifier;
    client = client;
    avatar = null;
    isDirectMessage = false;
    directMessagePartnerID = null;
  }

  Future<void> setDisplayName(String newName) async {
    await setDisplayNameInternal(newName);
    displayName = newName;
    onUpdate.add(null);
  }

  @protected
  Future<void> setDisplayNameInternal(String name);

  Future<void> setPushRule(PushRule rule);

  Future<void> setTypingStatus(bool typing);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;
    if (other.client != client) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;

  Color getColorOfUser(String userId);

  Future<void> enableE2EE();
}
