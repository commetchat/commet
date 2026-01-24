import 'package:commet/client/client.dart' as c;
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class MatrixSpaceRoomChunkPreview implements RoomPreview {
  SpaceRoomsChunk chunk;
  Client matrixClient;
  @override
  ImageProvider? avatar;

  @override
  String get displayName => chunk.name ?? chunk.canonicalAlias ?? roomId;

  @override
  String get roomId => chunk.roomId;

  @override
  String? get topic => chunk.topic;

  @override
  late c.RoomType type;

  MatrixSpaceRoomChunkPreview(this.chunk, this.matrixClient,
      {this.via = const []}) {
    avatar = chunk.avatarUrl != null
        ? MatrixMxcImage(chunk.avatarUrl!, matrixClient,
            doFullres: false, doThumbnail: true)
        : null;

    if (chunk.roomType == "m.space") {
      type = c.RoomType.space;
    } else {
      type = c.RoomType.defaultRoom;
    }
  }

  List<String> via;

  @override
  Color get color => MatrixPeer.hashColor(roomId);

  @override
  int? get numMembers => 0;

  @override
  RoomVisibility? get visibility => null;
}
