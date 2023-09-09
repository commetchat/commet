import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_room_permissions.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';

import '../../utils/rng.dart';

class SimulatedSpace extends Space {
  late String _identifier;
  late SimulatedClient _client;
  late String _displayName;
  late SimulatedRoomPermissions _permissions;
  final StreamController<void> _onUpdate = StreamController.broadcast();

  final NotifyingList<Room> _rooms = NotifyingList.empty(growable: true);

  final NotifyingList<RoomPreview> _previewRooms =
      NotifyingList.empty(growable: true);

  SimulatedSpace(displayName, client) {
    _identifier = RandomUtils.getRandomString(20);
    _displayName = displayName;
    _permissions = SimulatedRoomPermissions();
    _client = client;
  }

  PushRule _pushRule = PushRule.notify;

  @override
  PushRule get pushRule => _pushRule;

  @override
  String get developerInfo => "";

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility) {
    throw UnimplementedError();
  }

  @override
  Future<List<RoomPreview>> fetchChildren() async {
    return List.empty();
  }

  @override
  Future<void> changeAvatar(Uint8List bytes, String? mimeType) async {}

  @override
  Future<void> setPushRule(PushRule rule) async {
    _pushRule = rule;
    _onUpdate.add(null);
  }

  @override
  Color get color => Colors.redAccent;

  @override
  ImageProvider<Object>? get avatar => null;

  @override
  List<RoomPreview> get childPreviews => [];

  @override
  Client get client => _client;

  @override
  String get displayName => _displayName;

  @override
  String get identifier => _identifier;

  @override
  Future<void> loadExtra() async {}

  @override
  Stream<int> get onChildPreviewAdded => _previewRooms.onAdd;

  @override
  Stream<int> get onChildPreviewRemoved => _previewRooms.onRemove;

  @override
  Stream<void> get onChildPreviewsUpdated => _previewRooms.onListUpdated;

  @override
  Stream<Room> get onChildUpdated => throw UnimplementedError();

  @override
  Stream<void> get onChildrenUpdated => _rooms.onListUpdated;

  @override
  Stream<int> get onRoomAdded => _rooms.onAdd;

  @override
  Stream<void> get onUpdate => _onUpdate.stream;

  @override
  Permissions get permissions => _permissions;

  @override
  List<Room> get rooms => _rooms;

  @override
  Future<void> setDisplayName(String newName) async {
    _displayName = newName;
  }

  @override
  Future<void> setSpaceChildRoom(Room room) async {
    if (_rooms.contains(room)) return;
    _rooms.add(room);
  }

  void addRoom(Room room) {
    _rooms.add(room);
  }

  @override
  bool containsRoom(String identifier) {
    return _rooms.any((element) => element.identifier == identifier);
  }

  @override
  String get topic => "This is a simulated room";

  @override
  RoomVisibility get visibility => RoomVisibility.public;

  @override
  bool get fullyLoaded => true;
}
