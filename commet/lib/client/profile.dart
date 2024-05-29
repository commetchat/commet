import 'package:flutter/material.dart';

abstract class Profile {
  String get identifier;
  String get userName;
  String get displayName;
  String? get detail;
  ImageProvider? get avatar;
  Color get defaultColor;
}
