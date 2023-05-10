import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

import 'permissions.dart';

enum RoomVisibility { public, private, invite, knock }

enum PushRule { notify, mentionsOnly, dontNotify }

abstract class Room {
  late String identifier;
  late Client client;
  final Key key = UniqueKey();
  Timeline? timeline;
  late ImageProvider? avatar;
  late List<Peer> members;
  late String displayName;
  late bool isDirectMessage;
  late String? directMessagePartnerID;
  late Permissions permissions;
  bool get isMember => false;
  bool get isE2EE;
  StreamController<void> onUpdate = StreamController.broadcast();
  PushRule get pushRule;

  int get notificationCount;
  int get highlightedNotificationCount;

  Future<TimelineEvent?> sendMessage(String message,
      {TimelineEvent? inReplyTo});

  String get localId => "${client.identifier}:$identifier";

  Room(this.identifier, this.client) {
    identifier = identifier;
    client = client;
    members = List.empty(growable: true);
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;
    if (other.client != client) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;

  Future<void> enableE2EE();
}
