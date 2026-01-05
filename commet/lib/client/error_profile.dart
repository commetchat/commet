import 'package:commet/client/components/profile/profile_component.dart';
import 'package:flutter/material.dart';

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

  @override
  ImageProvider<Object>? get banner => null;
}
