import 'package:flutter/material.dart';

class Invitation {
  String senderId;
  String invitedToId;
  String invitationId;
  String? displayName;
  Color? color;
  ImageProvider? avatar;

  Invitation(
      {required this.senderId,
      required this.invitedToId,
      required this.invitationId,
      this.displayName,
      this.color,
      this.avatar});

  @override
  bool operator ==(Object other) {
    if (other is! Invitation) return false;
    return invitationId == other.invitationId;
  }

  @override
  int get hashCode => invitationId.hashCode;
}
