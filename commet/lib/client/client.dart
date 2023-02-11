import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum LoginType {
  loginPassword,
  token,
}

enum EventType {
  message,
  redaction,
  edit,
  invalid;
}

enum LoginResult { success, failed, error }

enum TimelineEventStatus {
  removed,
  error,
  sending,
  sent,
  synced,
  roomState,
}

TimelineEventStatus eventStatusFromInt(int intValue) =>
    TimelineEventStatus.values[intValue + 2];

/// Takes two [EventStatus] values and returns the one with higher
/// (better in terms of message sending) status.
TimelineEventStatus latestEventStatus(
        TimelineEventStatus status1, TimelineEventStatus status2) =>
    status1.intValue > status2.intValue ? status1 : status2;

extension EventStatusExtension on TimelineEventStatus {
  /// Returns int value of the event status.
  ///
  /// - -2 == removed;
  /// - -1 == error;
  /// -  0 == sending;
  /// -  1 == sent;
  /// -  2 == synced;
  /// -  3 == roomState;
  int get intValue => (index - 2);

  /// Return `true` if the `EventStatus` equals `removed`.
  bool get isRemoved => this == TimelineEventStatus.removed;

  /// Return `true` if the `EventStatus` equals `error`.
  bool get isError => this == TimelineEventStatus.error;

  /// Return `true` if the `EventStatus` equals `sending`.
  bool get isSending => this == TimelineEventStatus.sending;

  /// Return `true` if the `EventStatus` equals `roomState`.
  bool get isRoomState => this == TimelineEventStatus.roomState;

  /// Returns `true` if the status is sent or later:
  /// [EventStatus.sent], [EventStatus.synced] or [EventStatus.roomState].
  bool get isSent => [
        TimelineEventStatus.sent,
        TimelineEventStatus.synced,
        TimelineEventStatus.roomState
      ].contains(this);

  /// Returns `true` if the status is `synced` or `roomState`:
  /// [EventStatus.synced] or [EventStatus.roomState].
  bool get isSynced => [
        TimelineEventStatus.synced,
        TimelineEventStatus.roomState,
      ].contains(this);
}

class TimelineEvent {
  String eventId = "";
  EventType type = EventType.invalid;
  late TimelineEventStatus status;
  late Peer sender;
  late DateTime originServerTs;
}

abstract class Timeline {
  late List<TimelineEvent> events;

  Future<int> loadMoreHistory();
}

abstract class Peer {
  late String identifier;
  late String displayName;
  late ImageProvider? avatar;
  late Client client;
}

abstract class Room {
  late String identifier;
  late Client client;
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent inReplyTo});

  late ImageProvider? avatar;

  late String displayName;

  int notificationCount = 0;

  Room(this.identifier, this.client);

  Future<Timeline> getTimeline(
      {void Function(int index)? onChange,
      void Function(int index)? onRemove,
      void Function(int insertID)? onInsert,
      void Function()? onNewEvent,
      void Function()? onUpdate,
      String? eventContextId});
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
  late StreamController<void> onRoomListUpdated;
}

class ClientManager {
  late List<Client> _clients;
  List<Client> get clients => _clients;

  late List<Room> _rooms;
  List<Room> get rooms => _rooms;

  late StreamController<void> onSync;
  late StreamController<void> onRoomListUpdated;

  ClientManager() {
    _clients = List.empty(growable: true);
    _rooms = List.empty(growable: true);
    onSync = StreamController<void>();
    onRoomListUpdated = StreamController<void>();
  }

  void addClient(Client client) {
    _clients.add(client);

    client.onSync.stream.listen((_) => _synced());
    client.onRoomListUpdated.stream.listen((_) => _roomListUpdated());

    _updateRoomslist();
  }

  void log(Object s) {
    print('Client Manager] $s');
  }

  bool isLoggedIn() {
    return _clients[0].isLoggedIn();
    //return _clients.any((element) => element.isLoggedIn());
  }

  void _synced() {
    log("Syncing");
    _updateRoomslist();
    onSync.add(null);
  }

  void _roomListUpdated() {
    log("Room list updated");
    _updateRoomslist();
    onRoomListUpdated.add(null);
  }

  void _updateRoomslist() {
    var allRooms = List.empty(growable: true);

    for (var client in _clients) {
      allRooms.addAll(client.rooms);
    }

    var addRooms = allRooms.where((room) => !_rooms.any((e) =>
        e.runtimeType == room.runtimeType && e.identifier == room.identifier));

    log(addRooms);
    for (var room in addRooms) {
      _rooms.add(room);
    }

    var removeRooms = _rooms.where((room) => !allRooms.any((e) =>
        (e.runtimeType == room.runtimeType &&
            e.identifier == room.identifier)));

    log(removeRooms);

    for (var room in removeRooms) {
      log(room.runtimeType);
      _rooms.remove(room);
    }

    for (var room in _rooms) {
      log(room.identifier);
    }
  }
}
