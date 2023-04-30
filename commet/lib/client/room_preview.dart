import 'package:flutter/widgets.dart';

abstract class RoomPreview {
  String get roomId;
  ImageProvider? get avatar;
  String? get displayName;
  String? get topic;
}

class GenericRoomPreview implements RoomPreview {
  @override
  String roomId;

  @override
  ImageProvider? avatar;

  @override
  String? displayName;

  @override
  String? topic;

  GenericRoomPreview(this.roomId, {this.avatar, this.displayName, this.topic});
}
