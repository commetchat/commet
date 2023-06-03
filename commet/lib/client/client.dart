import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/room_preview.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:flutter/material.dart';

import 'peer.dart';

export 'package:commet/client/room.dart';
export 'package:commet/client/space.dart';
export 'package:commet/client/peer.dart';
export 'package:commet/client/timeline.dart';

enum LoginType {
  loginPassword,
  token,
}

enum LoginResult { success, failed, error, alreadyLoggedIn }

abstract class Client {
  Future<void> init(bool loadingFromCache);

  Future<void> logout();

  final String identifier;

  Peer? user;

  Client(this.identifier);

  bool isLoggedIn();

  ValueKey get key => ValueKey(identifier);

  bool get supportsE2EE;

  int? get maxFileSize;

  Future<LoginResult> login(
      LoginType type, String userIdentifier, String server,
      {String? password, String? token});

  final Map<String, Room> _rooms = {};
  final Map<String, Space> _spaces = {};
  final Map<String, Peer> _peers = {};

  final Map<String, RoomPreview> _spacePreviews = {};

  //Key is user ID
  final Map<String, Room> _directMessages = {};

  List<Room> directMessages = List.empty(growable: true);
  List<Room> singleRooms = List.empty(growable: true);

  List<Room> rooms = List.empty(growable: true);
  List<Space> spaces = List.empty(growable: true);
  List<Peer> peers = List.empty(growable: true);

  late StreamController<int> onRoomAdded = StreamController.broadcast();
  late StreamController<int> onSpaceAdded = StreamController.broadcast();
  late StreamController<int> onPeerAdded = StreamController.broadcast();

  late StreamController<void> onSync = StreamController.broadcast();

  bool spaceExists(String identifier) {
    return _spaces.containsKey(identifier);
  }

  bool roomExists(String identifier) {
    return _rooms.containsKey(identifier);
  }

  bool peerExists(String identifier) {
    return _peers.containsKey(identifier);
  }

  Room? getRoom(String identifier) {
    return _rooms[identifier];
  }

  Space? getSpace(String identifier) {
    return _spaces[identifier];
  }

  /// Fetches a peer from the server, handling any caching
  Peer fetchPeer(String identifier) {
    if (_peers.containsKey(identifier)) return _peers[identifier]!;

    var result = fetchPeerInternal(identifier);
    _peers[identifier] = result;

    return result;
  }

  void addRoom(Room room) {
    if (!_rooms.containsKey(room.identifier)) {
      _rooms[room.identifier] = room;
      rooms.add(room);
      int index = rooms.length - 1;

      if (room.isDirectMessage) {
        if (!_directMessages.containsKey(room.directMessagePartnerID!)) {
          _directMessages[room.directMessagePartnerID!] = room;
          directMessages.add(room);
        }
      }

      for (var space in spaces) {
        if (space.childPreviews
            .any((element) => element.roomId == room.identifier)) {
          space.addRoom(room);
        }
      }

      if (!spaces.any((space) => space.containsRoom(room.identifier))) {
        singleRooms.add(room);
      }

      onRoomAdded.add(index);
    }
  }

  void addSpace(Space space) {
    if (!_spaces.containsKey(space.identifier)) {
      _spaces[space.identifier] = space;
      spaces.add(space);
      int index = spaces.length - 1;
      onSpaceAdded.add(index);
    }
  }

  void addPeer(Peer peer) {
    if (!_peers.containsKey(peer.identifier)) {
      _peers[peer.identifier] = peer;
      peers.add(peer);
      int index = spaces.length - 1;
      onPeerAdded.add(index);
    }
  }

  Future<Room> createRoom(String name, RoomVisibility visibility,
      {bool enableE2EE = true});

  Future<Space> createSpace(String name, RoomVisibility visibility);

  Future<Space> joinSpace(String address);

  Future<Room> joinRoom(String address);

  Future<RoomPreview?> getSpacePreview(String address) async {
    if (_spacePreviews.containsKey(address)) {
      return _spacePreviews[address];
    }

    var preview = await getSpacePreviewInternal(address);
    if (preview != null) {
      _spacePreviews[address] = preview;
      return preview;
    }

    return null;
  }

  Future<RoomPreview?> getRoomPreviewInternal(String address);

  Future<RoomPreview?> getSpacePreviewInternal(String address);

  Future<void> setAvatar(Uint8List bytes, String mimeType);

  Future<void> setDisplayName(String name);

  Future<void> close() async {}

  Iterable<Room> getEligibleRoomsForSpace(Space space);

  @protected

  /// Fetches a peer from the server. does not need to implement caching
  Peer fetchPeerInternal(String identifier);
}
