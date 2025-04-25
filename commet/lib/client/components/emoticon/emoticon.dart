import 'dart:core';
import 'package:flutter/material.dart';

enum EmoticonUsage {
  sticker,
  emoji,
  all,
  inherit,
}

abstract class Emoticon {
  ImageProvider? get image;
  String get slug;
  String? get shortcode;
  String get key;

  EmoticonUsage get usage;

  bool get isSticker =>
      usage == EmoticonUsage.sticker || usage == EmoticonUsage.all;

  bool get isEmoji =>
      usage == EmoticonUsage.emoji || usage == EmoticonUsage.all;
}
