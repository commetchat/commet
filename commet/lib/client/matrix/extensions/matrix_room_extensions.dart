import 'dart:typed_data';

import 'package:matrix/matrix.dart';

extension MatrixExtensions on Room {
  Future<Map<String, dynamic>>? createEmoticonPack(
    String name,
    Uint8List? imageData,
  ) async {
    Uri? avatar;
    if (imageData != null) {
      avatar = await client.uploadContent(imageData);
    }

    var content = {
      "pack": {
        "display_name": name,
        if (avatar != null) "avatar_url": avatar.toString()
      }
    };

    String stateKey = name;

    // Check for existing and empty state keys, and reuse those keys first
    var existing = states['im.ponies.room_emotes'];
    if (existing != null) {
      for (var pair in existing.entries) {
        if (pair.value.content.isEmpty) {
          stateKey = pair.key;
          break;
        }
      }
    }

    await client.setRoomStateWithKey(
        id, "im.ponies.room_emotes", stateKey, content);

    var data =
        await client.getRoomStateWithKey(id, "im.ponies.room_emotes", stateKey);

    return {"key": stateKey, "content": data};
  }

  Future<Map<String, dynamic>>? createEmoticon(
      String packKey, String emoteName, Uint8List data) async {
    var content =
        await client.getRoomStateWithKey(id, "im.ponies.room_emotes", packKey);

    Uri url = await client.uploadContent(data);

    if (content['images'] == null) {
      content['images'] = {};
    }

    if (content['images'][emoteName] == null) {
      content['images'][emoteName] = {};
    }
    content['images'][emoteName]['url'] = url.toString();
    content['images'][emoteName]['display_name'] = emoteName;

    await client.setRoomStateWithKey(
        id, "im.ponies.room_emotes", packKey, content);

    return content;
  }

  Future<void>? deleteEmoticonPack(String packKey) async {
    await client.setRoomStateWithKey(id, "im.ponies.room_emotes", packKey, {});
  }

  Future<void> deleteEmoticon(String packKey, String emoteName) async {
    var content =
        await client.getRoomStateWithKey(id, "im.ponies.room_emotes", packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      images.remove(emoteName);
      content['images'] = images;
    }

    await client.setRoomStateWithKey(
        id, "im.ponies.room_emotes", packKey, content);
  }

  Future<void> renameEmoticon(
      String packKey, String emoteName, String newName) async {
    var content =
        await client.getRoomStateWithKey(id, "im.ponies.room_emotes", packKey);

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

    await client.setRoomStateWithKey(
        id, "im.ponies.room_emotes", packKey, content);
  }
}
