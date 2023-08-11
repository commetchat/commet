import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension MatrixExtensions on Client {
  CacheFileProvider getMxcThumbnail(String mxc, double width, double height) {
    var uri = Uri.parse(mxc);
    return CacheFileProvider("thumbnail_${width}x${height}_${mxc.toString()}",
        () async {
      return (await httpClient
              .get(uri.getThumbnail(this, width: width, height: height)))
          .bodyBytes;
    });
  }

  CacheFileProvider getMxcFile(String mxc) {
    var uri = Uri.parse(mxc);
    return CacheFileProvider(mxc.toString(), () async {
      return (await httpClient.get(uri.getDownloadLink(this))).bodyBytes;
    });
  }

  Future<RoomPreview?> getRoomPreview(String roomId) async {
    var state = await getRoomState(roomId);
    String? displayName;
    ImageProvider? avatar;
    String? topic;

    var nameState = state.where((element) => element.type == "m.room.name");
    if (nameState.isEmpty) return null;

    displayName = nameState.first.content['name'];
    var avatarState = state.where((element) => element.type == "m.room.avatar");
    if (avatarState.isNotEmpty) {
      var mxc = Uri.parse(avatarState.first.content['url']);
      var thumbnail = mxc.getThumbnail(this, width: 60, height: 60);
      avatar = NetworkImage(thumbnail.toString());
    }

    var topicState = state.where((element) => element.type == "m.room.topic");
    if (topicState.isNotEmpty) topic = topicState.first.content['topic'];

    return GenericRoomPreview(roomId,
        avatar: avatar, displayName: displayName, topic: topic);
  }

  Future<void> addEmoticonRoomPack(String roomId, String packKey) async {
    var state = BasicEvent(type: "im.ponies.emote_rooms", content: {});

    if (accountData.containsKey("im.ponies.emote_rooms")) {
      state = accountData["im.ponies.emote_rooms"]!;
    }

    if (!state.content.containsKey("rooms")) {
      state.content['rooms'] = {};
    }

    var rooms = state.content['rooms'] as Map;
    if (!rooms.containsKey(roomId)) {
      rooms[roomId] = {};
    }

    var roomPacks = rooms[roomId] as Map;
    roomPacks[packKey] = {};

    await setAccountData(userID!, "im.ponies.emote_rooms", state.content);
  }

  Future<void> removeEmoticonRoomPack(String roomId, String packKey) async {
    var state = BasicEvent(type: "im.ponies.emote_rooms", content: {});

    if (accountData.containsKey("im.ponies.emote_rooms")) {
      state = accountData["im.ponies.emote_rooms"]!;
    }

    if (!state.content.containsKey("rooms")) {
      state.content['rooms'] = {};
    }

    var rooms = state.content['rooms'] as Map;
    if (!rooms.containsKey(roomId)) {
      rooms[roomId] = {};
    }

    var roomPacks = rooms[roomId] as Map;
    roomPacks.remove(packKey);

    await setAccountData(userID!, "im.ponies.emote_rooms", state.content);
  }

  bool isEmoticonPackGloballyAvailable(String roomId, String packKey) {
    if (!accountData.containsKey("im.ponies.emote_rooms")) {
      return false;
    }

    var state = accountData["im.ponies.emote_rooms"]!.content;
    if (!state.containsKey("rooms")) {
      return false;
    }

    var rooms = state["rooms"] as Map;
    if (!rooms.containsKey(roomId)) {
      return false;
    }

    var roomData = rooms[roomId] as Map;

    return roomData.containsKey(packKey);
  }
}
