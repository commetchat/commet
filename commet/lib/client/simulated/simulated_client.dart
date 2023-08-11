import 'dart:async';
import 'dart:typed_data';
import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';

import '../client_manager.dart';

class SimulatedClient extends Client {
  bool _isLogged = false;

  SimulatedClient() : super(RandomUtils.getRandomString(20));

  @override
  Future<void> init(bool loadingFromCache) async {}

  @override
  int get maxFileSize => 10000000;

  @override
  bool isLoggedIn() => _isLogged;

  @override
  bool get supportsE2EE => false;

  @override
  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token}) async {
    LoginResult loginResult = LoginResult.success;
    _isLogged = true;

    _postLoginSuccess();
    return loginResult;
  }

  static Future<void> loadFromDB(ClientManager clientManager) async {
    var client = SimulatedClient();
    clientManager.addClient(client);
    client.login(LoginType.loginPassword, "alice", "");
    client.init(false);
  }

  @override
  Future<void> logout() async {
    _isLogged = false;
  }

  void _postLoginSuccess() {
    user = SimulatedPeer(this, "simulated@example.com", "Simulated",
        const AssetImage("assets/images/placeholder/generic/checker_red.png"));
    peers.add(user!);

    _updateRoomslist();
    _updateSpacesList();
    addRoom(SimulatedRoom("DM with Bob", this, isDm: true));
  }

  void _updateRoomslist() {
    addRoom(SimulatedRoom("Simulated Room", this));
    addRoom(SimulatedRoom("Simulated Room 2", this));
    addRoom(SimulatedRoom("Simulated Room 3", this));
    addRoom(SimulatedRoom("Simulated Room 4", this));
    addRoom(SimulatedRoom("Simulated Room 5", this));
    addRoom(SimulatedRoom("Simulated Room 6", this));
    addRoom(SimulatedRoom("Simulated Room 7", this));
  }

  void _updateSpacesList() {
    var space = SimulatedSpace("Simulated Space 1", this);
    for (var room in rooms) {
      space.addRoom(room);
    }
    addSpace(space);
    addSpace(SimulatedSpace("Simulated Space 2", this));
    addSpace(SimulatedSpace("Simulated Space 3", this));
    addSpace(SimulatedSpace("Simulated Space 4", this));
    addSpace(SimulatedSpace("Simulated Space 5", this));
    addSpace(SimulatedSpace("Simulated Space 6", this));
    addSpace(SimulatedSpace("Simulated Space 7", this));
    addSpace(SimulatedSpace("Simulated Space 8", this));
    addSpace(SimulatedSpace("Simulated Space 9", this));
    addSpace(SimulatedSpace("Simulated Space 10", this));

    Future.delayed(const Duration(seconds: 10), () {
      if (_isLogged) {
        addSpace(SimulatedSpace("Simulated Space 11", this));
        addSpace(SimulatedSpace("Simulated Space 12", this));
      }
    });
  }

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = false}) async {
    var room = SimulatedRoom(name, this);
    addRoom(room);
    return room;
  }

  @override
  Future<Space> createSpace(String name, RoomVisibility visibility) async {
    var space = SimulatedSpace(name, this);
    addSpace(space);
    return space;
  }

  @override
  Future<Space> joinSpace(String address) async {
    return await createSpace(address, RoomVisibility.public);
  }

  @override
  Future<RoomPreview?> getRoomPreviewInternal(String address) {
    // ignore: todo
// TODO: implement getRoomPreviewInternal
    throw UnimplementedError();
  }

  @override
  Future<RoomPreview?> getSpacePreviewInternal(String address) {
    // ignore: todo
// TODO: implement getSpacePreviewInternal
    throw UnimplementedError();
  }

  @override
  Future<Room> joinRoom(String address) {
    // ignore: todo
    // TODO: implement joinRoom
    throw UnimplementedError();
  }

  @override
  Future<void> setAvatar(Uint8List bytes, String mimeType) async {
    user!.avatar = MemoryImage(bytes);
  }

  @override
  Future<void> setDisplayName(String name) async {
    (user as SimulatedPeer).displayName = name;
  }

  @override
  Iterable<Room> getEligibleRoomsForSpace(Space space) {
    return rooms.where((room) => !space.containsRoom(room.identifier));
  }
}
