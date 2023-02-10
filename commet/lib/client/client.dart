import 'dart:async';

import 'package:flutter/material.dart';

enum LoginType {
  loginPassword,
  token,
}

enum EventType {
  message,
  redaction,
  edit,
}

enum LoginResult { success, failed, error }

class TimelineEvent {}

abstract class Timeline {
  late List<TimelineEvent> events;
}

abstract class Room {
  late String identifier;
  late Client client;
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent inReplyTo});

  late ImageProvider? avatar;

  late String displayName;

  int notificationCount = 0;

  Room(this.identifier, this.client);
}

abstract class Client {
  Future<void> init();

  Future<void> logout();

  bool isLoggedIn();

  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token});

  late List<Room> _rooms;

  List<Room> get rooms => _rooms;

  late StreamController<void> onSync;
}
