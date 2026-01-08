import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_pack.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_import_emoticon_pack_task.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart' as matrix;

/// Manages custom emoticon packs from the matrix user account state
class MatrixEmoticonComponent extends EmoticonComponent<MatrixClient> {
  static const roomEmotesStateKey = "im.ponies.room_emotes";
  static const globalEmoteRoomsStateKey = "im.ponies.emote_rooms";

  final StreamController<void> _onStateChanged = StreamController.broadcast();

  @override
  bool get canCreatePack => ownedPacks.isEmpty;

  @override
  MatrixClient client;

  String get ownerId => client.identifier;

  String get ownerDisplayName => client.self?.displayName ?? client.identifier;

  MatrixEmoticonStateManager state;

  MatrixEmoticonComponent(this.client, this.state) {
    refreshOwnedPacks();

    state.onStateChanged.listen((_) {
      refreshOwnedPacks();
      _onStateChanged.add(null);
    });
  }

  void refreshOwnedPacks() {
    final state = this.state.getAllStates();

    _ownedPacks = state.entries.where((e) {
      final val = e.value;
      if (val is Map<String, dynamic>) {
        return val.isNotEmpty;
      } else {
        return false;
      }
    }).map((e) {
      return MatrixEmoticonPack(this, e.key, e.value);
    }).toList();
  }

  @override
  Stream<void> get onStateChanged => _onStateChanged.stream;

  List<EmoticonPack> _ownedPacks = List.empty();

  @override
  List<EmoticonPack> get ownedPacks => _ownedPacks;

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
  Future<void> createEmoticonPack(String name, Uint8List? avatarData) async {
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

    await state.setState(stateKey, content);
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

    await state.setState(stateKey, content);

    task.complete();
  }

  String getNewPackKeyState(String packName) {
    var stateKey = packName;
    var states = state.getAllStates();

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
    var matrixPack = pack as MatrixEmoticonPack;
    return state.setState(matrixPack.stateKey, {});
  }

  @override
  List<EmoticonPack> globalPacks() {
    var matrixClient = client.getMatrixClient();

    if (!matrixClient.accountData.containsKey(globalEmoteRoomsStateKey))
      return [];

    var rooms = matrixClient.accountData[globalEmoteRoomsStateKey]!
        .content['rooms'] as Map<String, Object?>;

    var packs = List<EmoticonPack>.empty(growable: true);

    for (var roomId in rooms.keys) {
      var room = client.getRoom(roomId);
      var space = client.getSpace(roomId);

      if (room == null && space == null) continue;
      if (rooms[roomId] is! Map<String, dynamic>) {
        continue;
      }

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

  Future<void> deleteEmoticon(String packKey, String emoteName) async {
    var content = state.getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      images.remove(emoteName);
      content['images'] = images;
    }

    return state.setState(packKey, content);
  }

  Future<void> setPackUsages(String packKey, List<String>? usages) async {
    var content = state.getState(packKey);

    var pack = content['pack'] as Map<String, dynamic>?;

    if (pack == null) return;

    pack['usage'] = usages?.isEmpty == true ? null : usages;
    content['pack'] = pack;

    return state.setState(packKey, content);
  }

  Future<void> updatePack(String packKey,
      {EmoticonUsage? usage, String? name, Uint8List? imageData}) async {
    var content = state.getState(packKey);

    if (usage != null) {
      content['pack']['usage'] = switch (usage) {
        EmoticonUsage.sticker => ["sticker"],
        EmoticonUsage.emoji => ["emoticon"],
        EmoticonUsage.all => ["emoticon", "sticker"],
        EmoticonUsage.inherit => null,
      };
    }

    if (name != null) {
      content['pack']['display_name'] = name;
    }

    if (imageData != null) {
      Uri url = await client.getMatrixClient().uploadContent(imageData);
      content['pack']['avatar_url'] = url.toString();
    }

    return state.setState(packKey, content);
  }

  Future<void> updateEmoticon(
    String packKey,
    String emoteName, {
    Uint8List? data,
    String? mimeType,
    EmoticonUsage? usage,
    required Emoticon previous,
  }) async {
    var content = state.getState(packKey);

    var emoteState = content['images'][previous.shortcode!];

    if (usage != null) {
      emoteState['usage'] = switch (usage) {
        EmoticonUsage.sticker => ["sticker"],
        EmoticonUsage.emoji => ["emoticon"],
        EmoticonUsage.all => ["emoticon", "sticker"],
        EmoticonUsage.inherit => null,
      };
    }

    if (data != null) {
      Uri url = await client.getMatrixClient().uploadContent(data);
      emoteState['url'] = url.toString();
    }

    var pack = {"pack": content['pack'], "images": {}};

    var keys = content['images'].keys.toList();

    // construct a new map this way, to keep ordering :O
    for (var key in keys) {
      if (key == previous.shortcode) {
        pack['images'][emoteName] = emoteState;
      } else {
        pack['images'][key] = content['images'][key];
      }
    }

    await state.setState(packKey, pack);
  }

  Future<Map<String, dynamic>>? createEmoticon(
    String packKey,
    String emoteName,
    Uint8List data,
  ) async {
    var content = state.getState(packKey);

    Uri url = await client.getMatrixClient().uploadContent(data);

    if (content['images'] == null) {
      content['images'] = {};
    }

    if (content['images'][emoteName] == null) {
      content['images'][emoteName] = {};
    }
    content['images'][emoteName]['url'] = url.toString();
    content['images'][emoteName]['display_name'] = emoteName;

    await state.setState(packKey, content);
    return content;
  }

  @override
  List<EmoticonPack> get availablePacks => globalPacks() + UnicodeEmojis.packs!;

  Map<String, Map<String, String>> getEmotePacksFlat(
      matrix.ImagePackUsage emoticon) {
    var packs = globalPacks();

    var result = <String, Map<String, String>>{};

    for (var pack in packs) {
      var key = "${pack.displayName}-${pack.hashCode}";
      result[key] = <String, String>{};
      for (var emote in pack.emotes) {
        result[key]![emote.shortcode!] =
            (emote as MatrixEmoticon).emojiUrl.toString();
      }
    }

    return result;
  }
}
