import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_room_permissions.dart';
import 'package:commet/client/matrix/matrix_room_preview.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'components/emoticon/matrix_emoticon_pack.dart';
import 'matrix_peer.dart';

class MatrixSpace extends Space {
  late matrix.Room _matrixRoom;
  late matrix.Client _matrixClient;

  Uri? _avatarUrl;
  bool ignoreNextAvatarUpdate = false;

  @override
  String get topic => _matrixRoom.topic;

  @override
  String get developerInfo =>
      const JsonEncoder.withIndent('  ').convert(_matrixRoom.states);

  @override
  late final MatrixEmoticonComponent emoticons;

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

  MatrixSpace(client, matrix.Room room, matrix.Client matrixClient)
      : super(room.id, client) {
    _matrixRoom = room;
    _matrixClient = matrixClient;
    displayName = room.getLocalizedDisplayname();

    _matrixRoom.postLoad();

    room.onUpdate.stream.listen((event) {
      refresh();
      onUpdate.add(null);
    });

    client.onSync.stream.listen((event) {
      refresh();
    });

    permissions = MatrixRoomPermissions(_matrixRoom);

    emoticons = MatrixEmoticonComponent(
        MatrixRoomEmoticonHelper(_matrixRoom), this.client as MatrixClient);

    refresh();
  }

  void refresh() {
    displayName = _matrixRoom.getLocalizedDisplayname();

    if (_matrixRoom.avatar != null && _matrixRoom.avatar != _avatarUrl) {
      updateAvatarFromRoomState();
    }

    updateRoomsList();
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
        autoLoadFullRes: false);
    setAvatar(newAvatar: avatar);
  }

  void updateRoomsList() {
    for (var child in _matrixRoom.spaceChildren) {
      // reuse the existing room object
      var room = client.getRoom(child.roomId!);
      if (room != null) {
        if (!containsRoom(room.identifier)) {
          addRoom(room);
        }
      } else {}
    }
  }

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility) async {
    var room = await client.createRoom(name, visibility);
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
  void onRoomReorderedCallback(int oldIndex, int newIndex) {}

  @override
  Future<void> setDisplayNameInternal(String name) async {
    await _matrixRoom.setName(name);
  }

  @override
  Future<void> changeAvatar(Uint8List bytes, String? mimeType) async {
    var avatar = Image.memory(bytes).image;
    ignoreNextAvatarUpdate = true;
    setAvatar(newAvatar: avatar, newThumbnail: avatar);

    await _matrixRoom.setAvatar(matrix.MatrixImageFile(
        bytes: bytes,
        name: "avatar",
        mimeType: mimeType == "" ? null : mimeType));
  }

  @override
  Future<void> setSpaceChildRoomInternal(Room room) async {
    if (room is! MatrixRoom) {
      throw Exception("Invalid room type for this client");
    }

    await _matrixRoom.setSpaceChild(room.identifier);
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
    onUpdate.add(null);
  }
}
