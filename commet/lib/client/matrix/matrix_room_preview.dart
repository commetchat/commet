import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class MatrixSpaceRoomChunkPreview implements RoomPreview {
  SpaceRoomsChunk chunk;
  Client matrixClient;
  @override
  ImageProvider? avatar;

  @override
  String? get displayName => chunk.name;

  @override
  String get roomId => chunk.roomId;

  @override
  String? get topic => chunk.topic;

  MatrixSpaceRoomChunkPreview(this.chunk, this.matrixClient) {
    avatar = chunk.avatarUrl != null
        ? NetworkImage(chunk.avatarUrl!
            .getThumbnail(matrixClient, width: 60, height: 60)
            .toString())
        : null;
  }

  @override
  Color get color => MatrixPeer.hashColor(roomId);
}
