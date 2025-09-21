import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component_registry.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_room_preview.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/ui/pages/add_space_or_room/add_space_or_room.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'matrix_peer.dart';

class MatrixSpace extends Space {
  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;
  late MatrixClient _client;
  late MatrixRoomPermissions _permissions;
  late String _displayName;

  final StreamController<void> _onUpdate = StreamController.broadcast();
  final NotifyingList<Room> _rooms = NotifyingList.empty(growable: true);
  final NotifyingList<RoomPreview> _previews =
      NotifyingList.empty(growable: true);

  NotifyingList<Space> _subspaces = NotifyingList.empty(growable: true);

  final StreamController<Room> _onChildUpdated = StreamController.broadcast();

  ImageProvider? _avatar;

  Uri? _avatarUrl;
  bool ignoreNextAvatarUpdate = false;

  bool _fullyLoaded = false;

  late final List<SpaceComponent<MatrixClient, MatrixSpace>> _components;

  matrix.Room get matrixRoom => _matrixRoom;
  @override
  String get topic => _matrixRoom.topic;

  @override
  String get developerInfo =>
      const JsonEncoder.withIndent('  ').convert(_matrixRoom.states);

  @override
  Color get color => MatrixPeer.hashColor(_matrixRoom.id);
  @override
  PushRule get pushRule {
    switch (_matrixRoom.pushRuleState) {
      case matrix.PushRuleState.notify:
        return PushRule.notify;
      case matrix.PushRuleState.mentionsOnly:
        return PushRule.notify;
      case matrix.PushRuleState.dontNotify:
        return PushRule.dontNotify;
    }
  }

  @override
  RoomVisibility get visibility {
    switch (_matrixRoom.joinRules) {
      case matrix.JoinRules.public:
        return RoomVisibility.public;
      case matrix.JoinRules.knock:
        return RoomVisibility.knock;
      case matrix.JoinRules.invite:
        return RoomVisibility.invite;
      case matrix.JoinRules.private:
        return RoomVisibility.private;
      default:
        return RoomVisibility.private;
    }
  }

  @override
  ImageProvider<Object>? get avatar => _avatar;

  @override
  List<RoomPreview> get childPreviews => _previews;

  @override
  Client get client => _client;

  @override
  String get displayName => _displayName;

  @override
  String get identifier => _matrixRoom.id;

  @override
  Stream<int> get onChildRoomPreviewAdded => _previews.onAdd;

  @override
  Stream<int> get onChildRoomPreviewRemoved => _previews.onRemove;

  @override
  Stream<void> get onChildRoomPreviewsUpdated => _previews.onListUpdated;

  @override
  Stream<Room> get onChildRoomUpdated => _onChildUpdated.stream;

  @override
  Stream<void> get onChildRoomsUpdated => _rooms.onListUpdated;

  @override
  List<Space> get subspaces => _subspaces;

  @override
  Stream<int> get onChildSpaceAdded => _subspaces.onAdd;

  @override
  Stream<int> get onChildSpaceRemoved => _subspaces.onRemove;

  @override
  Stream<int> get onRoomAdded => _rooms.onAdd;

  @override
  Stream<int> get onRoomRemoved => _rooms.onRemove;

  @override
  Stream<void> get onUpdate => _onUpdate.stream;

  @override
  Permissions get permissions => _permissions;

  @override
  List<Room> get rooms => _rooms;

  @override
  bool get fullyLoaded => _fullyLoaded;

  late List<StreamSubscription> _subscriptions;

  @override
  bool get isTopLevel {
    for (var room in _matrixClient.rooms.where((r) => r.isSpace)) {
      if (room.spaceChildren.any((child) => child.roomId == _matrixRoom.id)) {
        return false;
      }
    }
    return true;
  }

  MatrixSpace(
      MatrixClient client, matrix.Room room, matrix.Client matrixClient) {
    _matrixRoom = room;
    _matrixClient = matrixClient;
    _client = client;
    _displayName = room.getLocalizedDisplayname();
    _permissions = MatrixRoomPermissions(_matrixRoom);
    refresh();

    _matrixRoom.postLoad();
    _components = ComponentRegistry.getMatrixSpaceComponents(client, this);

    _subscriptions = List.from([
      client.onRoomAdded.listen((_) => updateRoomsList()),
      client.onRoomRemoved.listen(onClientRoomRemoved),

      // Subscribe to all child update events
      _rooms.onAdd.listen(_onRoomAdded),
    ], growable: true);
  }

  void refresh() {
    _displayName = _matrixRoom.getLocalizedDisplayname();

    if (_matrixRoom.avatar != null && _matrixRoom.avatar != _avatarUrl) {
      updateAvatarFromRoomState();
    }

    updateRoomsList();
  }

  @override
  Future<void> close() async {
    _rooms.close();
    _onChildUpdated.close();
    _onUpdate.close();
    for (var sub in _subscriptions) {
      sub.cancel();
    }
  }

  void updateAvatarFromRoomState() {
    _avatarUrl = _matrixRoom.avatar;
    if (ignoreNextAvatarUpdate) {
      ignoreNextAvatarUpdate = false;
      return;
    }

    if (_matrixRoom.avatar != null) {
      updateAvatar();
    }
  }

  void updateAvatar() {
    var avatar = MatrixMxcImage(_matrixRoom.avatar!, _matrixClient,
        doThumbnail: true,
        thumbnailHeight: 128,
        fullResHeight: 384,
        autoLoadFullRes: false);
    _avatar = avatar;
  }

  void onClientRoomRemoved(int index) {
    var leftRoom = client.rooms[index];
    if (containsRoom(leftRoom.identifier)) {
      _rooms.remove(leftRoom);
    }
  }

  void updateRoomsList() {
    for (var child in _matrixRoom.spaceChildren) {
      var space = client.getSpace(child.roomId!);

      if (space == null) {
        subspaces.removeWhere((e) => e.identifier == child.roomId);
      }

      if (space != null) {
        if (!subspaces.any((s) => s.identifier == child.roomId)) {
          subspaces.add(space);

          _previews.removeWhere((p) => p.roomId == child.roomId);
        }
      } else {
        var room = client.getRoom(child.roomId!);

        if (room == null) {
          _rooms.removeWhere((e) => e.identifier == child.roomId);
        }

        if (room != null) {
          if (!containsRoom(room.identifier) &&
              !client.hasSpace(room.identifier)) {
            _rooms.add(room);
            _previews
                .removeWhere((element) => element.roomId == room.identifier);
          }
        }
      }
    }
  }

  void _onRoomAdded(int index) {
    var room = _rooms[index];
    _subscriptions.add(room.onUpdate.listen((event) {
      _onChildUpdated.add(room);
    }));
  }

  @override
  Future<Room> createRoom(String name, CreateRoomArgs args) async {
    var room = await client.createRoom(args);
    _matrixRoom.setSpaceChild(room.identifier);
    return room;
  }

  @override
  Future<List<RoomPreview>> fetchChildren() async {
    var response =
        await _matrixClient.getSpaceHierarchy(identifier, maxDepth: 5);

    return response.rooms
        .where((element) => element.roomId != identifier)
        .where((element) => !containsRoom(element.roomId))
        .map((e) => MatrixSpaceRoomChunkPreview(e, _matrixClient))
        .toList();
  }

  @override
  Future<void> changeAvatar(Uint8List bytes, String? mimeType) async {
    var avatar = Image.memory(bytes).image;
    ignoreNextAvatarUpdate = true;
    _avatar = avatar;

    await _matrixRoom.setAvatar(matrix.MatrixImageFile(
        bytes: bytes,
        name: "avatar",
        mimeType: mimeType == "" ? null : mimeType));
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    var newRule = _matrixRoom.pushRuleState;

    switch (rule) {
      case PushRule.notify:
        newRule = matrix.PushRuleState.notify;
        break;
      case PushRule.mentionsOnly:
        newRule = matrix.PushRuleState.mentionsOnly;
        break;
      case PushRule.dontNotify:
        newRule = matrix.PushRuleState.dontNotify;
        break;
    }

    await _matrixRoom.setPushRuleState(newRule);
    _onUpdate.add(null);
  }

  @override
  Future<void> loadExtra() async {
    var response =
        await _matrixClient.getSpaceHierarchy(identifier, maxDepth: 1);

    // read child rooms
    response.rooms
        .where((element) => element.roomId != identifier)
        .where((element) =>
            _matrixClient.getRoomById(element.roomId)?.membership !=
            matrix.Membership.join)
        .forEach((element) {
      _previews.add(MatrixSpaceRoomChunkPreview(element, _matrixClient));
    });

    _fullyLoaded = true;
  }

  @override
  Future<void> setDisplayName(String newName) async {
    _displayName = newName;
    await _matrixRoom.setName(newName);
  }

  @override
  Future<void> setSpaceChildRoom(Room room) async {
    await _matrixRoom.setSpaceChild(room.identifier);
  }

  @override
  bool containsRoom(String identifier) {
    return _rooms.any((element) => element.identifier == identifier);
  }

  @override
  T? getComponent<T extends SpaceComponent>() {
    for (var component in _components) {
      if (component is T) return component as T;
    }

    return null;
  }
}
