import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/room.dart';
import 'package:flutter/material.dart';

abstract class Space {
  late String identifier;
  late Client client;
  late ImageProvider? avatar;
  late List<Room> rooms = List.empty(growable: true);
  late Key key = UniqueKey();

  late String displayName;
  int notificationCount = 0;

  Space(this.identifier, this.client);

  StreamController<void> onUpdate = StreamController.broadcast();

  late StreamController<int> onRoomAdded = StreamController.broadcast();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Space) return false;

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}
