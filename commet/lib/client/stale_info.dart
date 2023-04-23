import 'package:flutter/material.dart';

class StalePeerInfo {
  int index;
  String? displayName;
  String? identifier;
  ImageProvider? avatar;
  StalePeerInfo(
      {required this.index, this.displayName, this.identifier, this.avatar});
}

class StaleSpaceInfo {
  int index;
  String? name;
  ImageProvider? avatar;
  ImageProvider? userAvatar;
  StaleSpaceInfo(
      {required this.index, this.name, this.avatar, this.userAvatar});
}
