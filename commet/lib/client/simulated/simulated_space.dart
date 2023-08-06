import 'dart:math';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/simulated/simulated_room_permissions.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:flutter/material.dart';

import '../../utils/rng.dart';

class SimulatedSpace extends Space {
  SimulatedSpace(displayName, client)
      : super(RandomUtils.getRandomString(20), client) {
    this.displayName = displayName;

    var images = [
      "assets/images/placeholder/generic/checker_green.png",
      "assets/images/placeholder/generic/checker_purple.png",
      "assets/images/placeholder/generic/checker_orange.png"
    ];
    var placeholderImageIndex = Random().nextInt(images.length);

    var avatar = AssetImage(images[placeholderImageIndex]);

    setAvatar(newAvatar: avatar, newThumbnail: avatar);

    permissions = SimulatedRoomPermissions();
  }

  PushRule _pushRule = PushRule.notify;

  @override
  PushRule get pushRule => _pushRule;

  @override
  String get developerInfo => "";

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  Future<Room> createRoom(String name, RoomVisibility visibility) {
    // ignore: todo
// TODO: implement createSpaceChild
    throw UnimplementedError();
  }

  @override
  void onRoomReorderedCallback(int oldIndex, int newIndex) {}

  @override
  Future<List<RoomPreview>> fetchChildren() async {
    return List.empty();
  }

  @override
  Future<void> setDisplayNameInternal(String name) async {
    displayName = name;
  }

  @override
  Future<void> changeAvatar(Uint8List bytes, String? mimeType) async {
    var avatar = Image.memory(bytes).image;
    setAvatar(newAvatar: avatar, newThumbnail: avatar);
  }

  @override
  Future<void> setSpaceChildRoomInternal(Room room) async {
    addRoom(room);
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    _pushRule = rule;
    onUpdate.add(null);
  }

  @override
  // TODO: implement emoticons
  EmoticonComponent? get emoticons => null;
}
