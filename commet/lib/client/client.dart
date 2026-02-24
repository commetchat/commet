import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/auth.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:flutter/material.dart';

import 'peer.dart';

export 'package:commet/client/room.dart';
export 'package:commet/client/space.dart';
export 'package:commet/client/peer.dart';
export 'package:commet/client/timeline.dart';

enum LoginType { loginPassword, token }

class ClientConnectionStatusUpdate {
  ClientConnectionStatus status;
  double? progress;

  ClientConnectionStatusUpdate(this.status);
}

enum ClientConnectionStatus { unknown, connected, connecting, disconnected }

enum RoomType {
  defaultRoom,
  photoAlbum,
  space,
  voipRoom,
  calendar;
}

extension ToIcon on RoomType {
  IconData get icon {
    return switch (this) {
      RoomType.defaultRoom => Icons.tag,
      RoomType.photoAlbum => Icons.photo,
      RoomType.space => Icons.spoke,
      RoomType.voipRoom => Icons.volume_up,
      RoomType.calendar => Icons.calendar_month,
    };
  }
}

extension ToString on RoomType {
  String get string {
    return switch (this) {
      RoomType.defaultRoom => "Chat Room",
      RoomType.photoAlbum => "Photo Album",
      RoomType.space => "Space",
      RoomType.voipRoom => "Voice Chat",
      RoomType.calendar => "Calendar",
    };
  }
}

class CreateRoomArgs {
  String? name;
  RoomVisibility? visibility;
  bool? enableE2EE;
  RoomType roomType;
  String? topic;

  CreateRoomArgs({
    this.name,
    this.visibility,
    this.enableE2EE,
    this.topic,
    this.roomType = RoomType.defaultRoom,
  });
}

enum LoginResult {
  success,
  failed,
  error,
  cancelled,
  alreadyLoggedIn,
  invalidUsernameOrPassword,
  userDeactivated
}

abstract class Client {
  /// Local identifier for this client instance
  String get identifier;

  /// The Peer owned by the current user session
  Profile? self;

  ValueKey get key => ValueKey(identifier);

  /// True if the client protocol supports End to End Encryption
  bool get supportsE2EE;

  /// Max size in bytes for uploaded files
  int? get maxFileSize;

  /// Gets a list of rooms which do not belong to any spaces
  List<Room> get singleRooms;

  /// Gets list of all rooms
  List<Room> get rooms;

  /// Gets list of all spaces
  List<Space> get spaces;

  /// Gets list of all currently known users
  List<Peer> get peers;

  /// When a room is added, this will be called with the index of the new room
  Stream<int> get onRoomAdded;

  /// When a space is added, this will be called with the index of the new space
  Stream<int> get onSpaceAdded;

  /// When a room is removed, this will be called with the index of the room which was removed
  Stream<int> get onRoomRemoved;

  /// When a space is removed, this will be called with the index of the space which was removed
  Stream<int> get onSpaceRemoved;

  /// When a new peer is found, this will be called with the index of the new peer
  Stream<int> get onPeerAdded;

  /// When the client receives an update from the server, this will be called
  Stream<void> get onSync;

  StoredStreamController<ClientConnectionStatusUpdate>
      get connectionStatusChanged;

  Future<void> init(bool loadingFromCache, {bool isBackgroundService = false});

  Future<(bool, List<LoginFlow>?)> setHomeserver(Uri uri);

  Future<LoginResult> executeLoginFlow(LoginFlow flow);

  /// Logout and invalidate the current session
  Future<void> logout();

  bool isLoggedIn();

  /// Returns true if the client is a member of the given space
  bool hasSpace(String identifier);

  /// Returns true if the client is a member of the given room
  bool hasRoom(String identifier);

  /// Returns true if the client knows of this peer
  bool hasPeer(String identifier);

  /// Gets a room by ID. only returns rooms which the client is a member of, otherwise null
  Room? getRoom(String identifier);

  /// Gets a room by alias. only returns rooms which the client is a member of, otherwise null
  Room? getRoomByAlias(String identifier);

  /// Gets a space by ID. only returns spaces which the client is a member of, otherwise null
  Space? getSpace(String identifier);

  /// Create a new room
  Future<Room> createRoom(CreateRoomArgs args);

  /// Create a new space
  Future<Space> createSpace(CreateRoomArgs args);

  /// Join an existing space by address
  Future<Space> joinSpace(String address);

  /// Join an existing room by address
  Future<Room> joinRoom(String address);

  Future<Room> joinRoomFromPreview(RoomPreview preview);

  /// Leaves a room
  Future<void> leaveRoom(Room room);

  /// Leaves a space
  Future<void> leaveSpace(Space space);

  /// Queries the server for information about a space which this client is not a member of
  Future<RoomPreview?> getSpacePreview(String address);

  /// Queries the server for information about a room which this client is not a member of
  Future<RoomPreview?> getRoomPreview(String address);

  /// Update the current user avatar
  Future<void> setAvatar(Uint8List bytes, String mimeType);

  /// Set the display name of the current user
  Future<void> setDisplayName(String name);

  /// End the current session and prepare for disposal
  Future<void> close();

  /// Find all the rooms which could be added to a given space
  Iterable<Room> getEligibleRoomsForSpace(Space space);

  /// Build a widget for display in the developer options debug menu
  Widget buildDebugInfo();

  T? getComponent<T extends Component>();

  List<T>? getAllComponents<T extends Component>();
}
