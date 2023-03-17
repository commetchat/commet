import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

import 'permissions.dart';

enum RoomVisibility {
  public,
  private,
}

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

  int notificationCount = 0;

  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent? inReplyTo});

  Room(this.identifier, this.client) {
    identifier = identifier;
    client = client;
    members = List.empty(growable: true);
    avatar = null;
    isDirectMessage = false;
    directMessagePartnerID = null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
