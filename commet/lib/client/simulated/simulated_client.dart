import 'dart:async';
import 'dart:typed_data';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/invitation.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/rng.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:flutter/material.dart';

import '../client_manager.dart';

class SimulatedClient extends Client {
  bool _isLogged = false;
  late String _id;

  late List<Component<SimulatedClient>> _components;

  final NotifyingList<Room> _rooms = NotifyingList.empty(
    growable: true,
  );
  final NotifyingList<Space> _spaces = NotifyingList.empty(
    growable: true,
  );

  final NotifyingList<Peer> _peers = NotifyingList.empty(
    growable: true,
  );

  final StreamController _onSync = StreamController.broadcast();

  SimulatedClient() {
    _id = RandomUtils.getRandomString(20);

    _components = ComponentRegistry.getSimulatedComponents(this);
  }

  @override
  Future<void> init(bool loadingFromCache,
      {bool isBackgroundService = false}) async {}

  @override
  int get maxFileSize => 10000000;

  @override
  bool isLoggedIn() => _isLogged;

  @override
  bool get supportsE2EE => false;

  @override
  String get identifier => _id;

  @override
  Stream<int> get onPeerAdded => _peers.onAdd;

  @override
  Stream<int> get onRoomAdded => _rooms.onAdd;

  @override
  Stream<int> get onSpaceAdded => _spaces.onAdd;

  @override
  Stream<int> get onRoomRemoved => _rooms.onRemove;

  @override
  Stream<int> get onSpaceRemoved => _spaces.onRemove;

  @override
  Stream<void> get onSync => _onSync.stream;

  @override
  List<Peer> get peers => _peers;

  @override
  List<Room> get rooms => _rooms;

  @override
  List<Room> get singleRooms => [];

  @override
  List<Space> get spaces => _spaces;

  @override
  List<Room> get directMessages => throw UnimplementedError();

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

  @override
  List<Invitation> get invitations => [];

  void _postLoginSuccess() {
    self = SimulatedPeer(
      this,
      "simulated@example.com",
      "Simulated",
    );
    peers.add(self!);

    _updateRoomslist();
    _updateSpacesList();
    _rooms.add(SimulatedRoom("DM with Bob", this, isDm: true));
  }

  void _updateRoomslist() {
    _rooms.add(SimulatedRoom("Simulated Room", this));
    _rooms.add(SimulatedRoom("Simulated Room 2", this));
  }

  void _updateSpacesList() {
    var space = SimulatedSpace("Simulated Space 1", this);
    for (var room in rooms) {
      space.addRoom(room);
    }
    _spaces.add(space);
  }

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = false}) async {
    var room = SimulatedRoom(name, this);
    _rooms.add(room);
    return room;
  }

  @override
  Future<Space> createSpace(String name, RoomVisibility visibility) async {
    var space = SimulatedSpace(name, this);
    _spaces.add(space);
    return space;
  }

  @override
  Future<Space> joinSpace(String address) async {
    return await createSpace(address, RoomVisibility.public);
  }

  @override
  Future<Room> joinRoom(String address) async {
    var room = SimulatedRoom("New Room", this);
    _rooms.add(room);
    return room;
  }

  @override
  Future<void> setAvatar(Uint8List bytes, String mimeType) async {
    self!.avatar = MemoryImage(bytes);
  }

  @override
  Future<void> setDisplayName(String name) async {
    (self as SimulatedPeer).displayName = name;
  }

  @override
  Iterable<Room> getEligibleRoomsForSpace(Space space) {
    return rooms.where((room) => !space.containsRoom(room.identifier));
  }

  @override
  Widget buildDebugInfo() {
    return const Placeholder();
  }

  @override
  Future<Room?> createDirectMessage(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> acceptInvitation(Invitation invitation) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectInvitation(Invitation invitation) {
    throw UnimplementedError();
  }

  @override
  Peer getPeer(String identifier) {
    return _peers.firstWhere((element) => element.identifier == identifier);
  }

  @override
  Room? getRoom(String identifier) {
    return _rooms.tryFirstWhere((element) => element.identifier == identifier);
  }

  @override
  Future<RoomPreview?> getRoomPreview(String address) async {
    return null;
  }

  @override
  Space? getSpace(String identifier) {
    return _spaces.tryFirstWhere((element) => element.identifier == identifier);
  }

  @override
  Future<RoomPreview?> getSpacePreview(String address) async {
    return null;
  }

  @override
  bool hasPeer(String identifier) {
    return _peers
        .where((element) => element.identifier == identifier)
        .isNotEmpty;
  }

  @override
  bool hasRoom(String identifier) {
    return _rooms
        .where((element) => element.identifier == identifier)
        .isNotEmpty;
  }

  @override
  bool hasSpace(String identifier) {
    return _spaces
        .where((element) => element.identifier == identifier)
        .isNotEmpty;
  }

  @override
  Future<void> close() async {}

  void addRoom(SimulatedRoom room) {
    _rooms.add(room);
  }

  void addSpace(SimulatedSpace space) {
    _spaces.add(space);
  }

  void addPeer(SimulatedPeer peer) {
    _peers.add(peer);
  }

  @override
  T? getComponent<T extends Component>() {
    for (var component in _components) {
      if (component is T) return component as T;
    }

    return null;
  }

  @override
  List<T>? getAllComponents<T extends Component<Client>>() {
    List<T> components = List.empty(growable: true);
    for (var component in _components) {
      if (component is T) {
        components.add(component as T);
      }
    }

    return components;
  }

  @override
  Future<void> leaveRoom(Room room) async {
    rooms.remove(room);
  }

  @override
  Future<void> leaveSpace(Space space) async {
    spaces.remove(space);
  }

  @override
  StoredStreamController<ClientConnectionStatusUpdate> connectionStatusChanged =
      StoredStreamController();
}
