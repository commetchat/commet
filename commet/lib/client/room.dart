import 'package:commet/client/client.dart';
import 'package:commet/client/timeline.dart';
import 'package:flutter/material.dart';

abstract class Room {
  late String identifier;
  late Client client;
  final Key key = UniqueKey();
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent inReplyTo});

  late ImageProvider? avatar;

  late String displayName;

  int notificationCount = 0;

  Room(this.identifier, this.client) {
    identifier = identifier;
    client = client;
  }

  Future<Timeline> getTimeline(
      {void Function(int index)? onChange,
      void Function(int index)? onRemove,
      void Function(int insertID)? onInsert,
      void Function()? onNewEvent,
      void Function()? onUpdate,
      String? eventContextId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Room) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
