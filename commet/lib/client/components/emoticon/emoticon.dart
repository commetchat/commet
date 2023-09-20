import 'dart:core';
import 'package:flutter/material.dart';

abstract class Emoticon {
  ImageProvider? get image;
  String get slug;
  String? get shortcode;
  String get key;

  bool get isMarkedEmoji;
  bool get isMarkedSticker;

  bool get isSticker;
  bool get isEmoji;
}
