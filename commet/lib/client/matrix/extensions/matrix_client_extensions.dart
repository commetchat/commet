import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/room.dart' show RoomVisibility;
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/generated/fixed_model.dart';

extension MatrixExtensions on Client {
  Future<FileResponse> getContentFromUri(Uri uri) {
    return getContent(uri.authority, uri.pathSegments.first);
  }

  Future<FileResponse> getContentThumbnailFromUri(
      Uri uri, int width, int height) {
    return getContentThumbnail(
        uri.authority, uri.pathSegments.first, width, height);
  }

  Future<RoomPreview?> getRoomPreview(String roomId) async {
    var result = await request(RequestType.GET,
        "/client/unstable/im.nheko.summary/rooms/${Uri.encodeComponent(roomId)}/summary");

    var name = result["name"] as String?;
    var id = result["room_id"] as String?;
    var avatar = result["avatar_url"] as String?;
    var topic = result["topic"] as String?;
    var numMembers = result["num_joined_members"] as int?;
    var joinRule = result["join_rule"] as String?;

    var visibility = switch (joinRule) {
      "public" => RoomVisibility.public,
      "knock" => RoomVisibility.knock,
      "invite" => RoomVisibility.invite,
      "private" => RoomVisibility.private,
      _ => RoomVisibility.private,
    };

    if (name != null && id != null) {
      ImageProvider? image;
      if (avatar != null) {
        var mxc = Uri.parse(avatar);
        image = MatrixMxcImage(mxc, autoLoadFullRes: false, this);
      }

      return GenericRoomPreview(id,
          displayName: name,
          type: RoomPreviewType.room,
          avatar: image,
          numMembers: numMembers,
          visibility: visibility,
          topic: topic);
    }

    return null;
  }

  Future<void> addEmoticonRoomPack(String roomId, String packKey) async {
    var state = BasicEvent(
        type: MatrixEmoticonComponent.globalEmoteRoomsStateKey, content: {});

    if (accountData
        .containsKey(MatrixEmoticonComponent.globalEmoteRoomsStateKey)) {
      state = accountData[MatrixEmoticonComponent.globalEmoteRoomsStateKey]!;
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

    await setAccountData(userID!,
        MatrixEmoticonComponent.globalEmoteRoomsStateKey, state.content);
  }

  Future<void> removeEmoticonRoomPack(String roomId, String packKey) async {
    var state = BasicEvent(
        type: MatrixEmoticonComponent.globalEmoteRoomsStateKey, content: {});

    if (accountData
        .containsKey(MatrixEmoticonComponent.globalEmoteRoomsStateKey)) {
      state = accountData[MatrixEmoticonComponent.globalEmoteRoomsStateKey]!;
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

    await setAccountData(userID!,
        MatrixEmoticonComponent.globalEmoteRoomsStateKey, state.content);
  }

  bool isEmoticonPackGloballyAvailable(String roomId, String packKey) {
    if (!accountData
        .containsKey(MatrixEmoticonComponent.globalEmoteRoomsStateKey)) {
      return false;
    }

    var state =
        accountData[MatrixEmoticonComponent.globalEmoteRoomsStateKey]!.content;
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

  // This is stupid, is there a better way to do this?
  Future<bool> isRoomAliasAvailable(String alias) async {
    try {
      await request(
        RequestType.GET,
        '/client/v3/directory/room/${Uri.encodeComponent(alias)}',
      );
      return false;
    } catch (exception) {
      if (exception is MatrixException) {
        if (exception.error == MatrixError.M_NOT_FOUND) {
          return true;
        }
      }
      return false;
    }
  }
}
