import 'dart:ui';

import 'package:commet/client/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/image_provider.dart';

class ErrorProfile implements Profile {
  @override
  ImageProvider<Object>? get avatar => null;

  @override
  Color get defaultColor => Colors.red;

  @override
  String? get detail => null;

  @override
  String get displayName => "Error";

  @override
  String get identifier => "Error";

  @override
  String get userName => "Error";
}
