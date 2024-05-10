import 'dart:typed_data';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_pack.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_import_emoticon_pack_task.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';

/// Manages custom emoticon packs from the matrix user account state
class MatrixEmoticonComponent extends EmoticonComponent<MatrixClient>
    implements NeedsPostLoginInit {
  static const roomEmotesStateKey = "im.ponies.room_emotes";
  static const emoteRoomsStateKey = "im.ponies.emote_rooms";

  @override
  bool get canCreatePack => ownedPacks.isEmpty;

  @override
  MatrixClient client;

  final NotifyingList<EmoticonPack> _packs =
      NotifyingList.empty(growable: true);

  MatrixEmoticonComponent(this.client);

  @override
  void postLoginInit() {
    var state = getAllStates();

    if (state.isEmpty) return;

    for (var key in state.keys) {
      var value = state[key]!;
      if (value['pack'] == null && value['images'] == null) continue;
      var pack = MatrixEmoticonPack(this, key, value);
      _packs.add(pack);
    }
  }

  @override
  Stream<int> get onOwnedPackAdded => _packs.onAdd;

  @override
  List<EmoticonPack> get ownedPacks => _packs;

  String getDefaultDisplayName() {
    return "Personal";
  }

  ImageProvider? getDefaultImage() {
    return null;
  }

  IconData? getDefaultIcon() {
    return Icons.star;
  }

  bool isGloballyAvailable(String packId) {
    return true;
  }

  @override
  Future<EmoticonPack> createEmoticonPack(
      String name, Uint8List? avatarData) async {
    Uri? avatar;
    if (avatarData != null) {
      avatar = await client.getMatrixClient().uploadContent(avatarData);
    }

    var content = {
      "pack": {
        "display_name": name,
        if (avatar != null) "avatar_url": avatar.toString()
      }
    };

    String stateKey = getNewPackKeyState(name);

    await setState(stateKey, content);
    var pack = MatrixEmoticonPack(this, stateKey, content);
    _packs.add(pack);
    return pack;
  }

  @override
  Future<void> importEmoticonPack(String name, int avatarIndex,
      List<String> names, List<Uint8List> imageDatas) async {
    var task = MatrixImportEmoticonPackTask(imageDatas, client);
    backgroundTaskManager.addTask(task);
    var uris = await task.uploadImages();

    var content = <String, dynamic>{
      "pack": {
        "display_name": name,
        "avatar_url": uris[avatarIndex].toString(),
      },
      "images": <String, dynamic>{}
    };

    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      content["images"]![name] = {
        "display_name": name,
        "url": uris[i]!.toString()
      };
    }

    String stateKey = getNewPackKeyState(name);

    await setState(stateKey, content);

    var pack = MatrixEmoticonPack(this, stateKey, content);
    _packs.add(pack);
    task.complete();
  }

  String getNewPackKeyState(String packName) {
    var stateKey = packName;
    var states = getAllStates();

    // Check for existing and empty state keys, and reuse those keys first
    for (var pair in states.entries) {
      if (pair.value.isEmpty) {
        stateKey = pair.key;
        break;
      }
    }

    return stateKey;
  }

  @override
  Future<void> deleteEmoticonPack(EmoticonPack pack) {
    _packs.remove(pack);
    var matrixPack = pack as MatrixEmoticonPack;
    return setState(matrixPack.stateKey, {});
  }

  @override
  List<EmoticonPack> globalPacks() {
    var matrixClient = client.getMatrixClient();

    if (!matrixClient.accountData.containsKey(emoteRoomsStateKey)) return [];

    var rooms = matrixClient.accountData[emoteRoomsStateKey]!.content['rooms']
        as Map<String, Object?>;

    var packs = List<EmoticonPack>.empty(growable: true);

    for (var roomId in rooms.keys) {
      var room = client.getRoom(roomId);
      var space = client.getSpace(roomId);

      if (room == null && space == null) continue;

      var packKeys = rooms[roomId] as Map<String, dynamic>;

      for (var packKey in packKeys.keys) {
        List? emoji;

        if (room != null) {
          var component = room.getComponent<RoomEmoticonComponent>();
          if (component != null) {
            emoji = component.ownedPacks;
          }
        } else if (space != null) {
          var component = space.getComponent<SpaceEmoticonComponent>();
          if (component != null) {
            emoji = component.ownedPacks;
          }
        }

        if (emoji == null) continue;

        var matchingPacks =
            emoji.where((element) => element.identifier == packKey);

        if (matchingPacks.isEmpty) continue;

        packs.add(matchingPacks.first);
      }
    }

    return packs;
  }

  Map<String, dynamic> getState(String packKey) {
    return client
            .getMatrixClient()
            .accountData['im.ponies.user_emotes']
            ?.content ??
        {};
  }

  Map<String, dynamic> getAllStates() {
    //These keys are kind of irrelevant, since they dont actually get used for
    //the state, its just easier this way because it makes it similar to rooms state
    var state = getState("personal");
    if (state.isEmpty) return {};
    return {"personal": state};
  }

  Future<void> setState(String packKey, Map<String, dynamic> content) {
    return client.getMatrixClient().setAccountData(
        client.getMatrixClient().userID!, "im.ponies.user_emotes", content);
  }

  Future<void> deleteEmoticon(String packKey, String emoteName) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      images.remove(emoteName);
      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> renameEmoticon(
      String packKey, String emoteName, String newName) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      var image = images[emoteName] as Map<String, dynamic>?;
      images.remove(emoteName);

      if (image != null) {
        image['display_name'] = newName;
        images[newName] = image;
      }

      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> setEmoticonUsages(
      String packKey, String emoteName, List<String>? usages) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;

      if (images.containsKey(emoteName)) {
        var emote = images[emoteName] as Map<String, dynamic>;

        emote.remove('usage');

        if (usages != null && usages.isNotEmpty) {
          emote['usage'] = usages;
        }

        images[emoteName] = emote;
      }

      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> setPackUsages(String packKey, List<String>? usages) async {
    var content = getState(packKey);

    var pack = content['pack'] as Map<String, dynamic>?;

    if (pack == null) return;

    pack['usage'] = usages?.isEmpty == true ? null : usages;
    content['pack'] = pack;

    return setState(packKey, content);
  }

  Future<Map<String, dynamic>>? createEmoticon(
    String packKey,
    String emoteName,
    Uint8List data,
  ) async {
    var content = getState(packKey);

    Uri url = await client.getMatrixClient().uploadContent(data);

    if (content['images'] == null) {
      content['images'] = {};
    }

    if (content['images'][emoteName] == null) {
      content['images'][emoteName] = {};
    }
    content['images'][emoteName]['url'] = url.toString();
    content['images'][emoteName]['display_name'] = emoteName;

    await setState(packKey, content);
    return content;
  }
}
