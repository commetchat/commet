import 'package:flutter/material.dart';

class Invitation {
  String roomId;
  String? displayName;
  String? senderId;
  Color? color;
  ImageProvider? avatar;

  Invitation(
      {required this.roomId,
      this.displayName,
      this.color,
      this.avatar,
      this.senderId});

  @override
  bool operator ==(Object other) {
    if (other is! Invitation) return false;
    return roomId == other.roomId;
  }

  @override
  int get hashCode => roomId.hashCode;
}
