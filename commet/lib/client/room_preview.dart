import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

enum RoomPreviewType { room, space, inaccessible }

abstract class RoomPreview {
  String get roomId;
  ImageProvider? get avatar;
  String get displayName;
  String? get topic;
  Color get color;
  RoomType? get type;
  int? get numMembers;
  RoomVisibility? get visibility;
}

class GenericRoomPreview implements RoomPreview {
  @override
  String roomId;

  @override
  ImageProvider? avatar;

  @override
  String displayName;

  @override
  String? topic;

  int? numMembers;

  RoomType? type;

  @override
  GenericRoomPreview(this.roomId,
      {this.avatar,
      required this.displayName,
      required this.type,
      this.numMembers,
      this.visibility,
      this.topic});

  @override
  Color get color => Colors.grey;

  @override
  RoomVisibility? visibility;
}
