import 'package:flutter/material.dart';

enum RoomPreviewType { room, space }

abstract class RoomPreview {
  String get roomId;
  ImageProvider? get avatar;
  String get displayName;
  String? get topic;
  Color get color;
  RoomPreviewType get type;
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

  GenericRoomPreview(this.roomId,
      {this.avatar, required this.displayName, required this.type, this.topic});

  @override
  Color get color => Colors.grey;

  @override
  RoomPreviewType type;
}
