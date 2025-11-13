import 'package:flutter/material.dart';

abstract class Member {
  String get identifier;
  String get userName;
  String get displayName;
  String? get detail;
  String? get avatarId;
  ImageProvider? get avatar;
  Color get defaultColor;
}
