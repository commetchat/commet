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

  /// Where a custom emoticon's image lives (an `mxc://` URI on Matrix), or
  /// null for Unicode emoji.
  Uri? get url => null;

  EmoticonUsage get usage;

  bool get isSticker =>
      usage == EmoticonUsage.sticker || usage == EmoticonUsage.all;

  bool get isEmoji =>
      usage == EmoticonUsage.emoji || usage == EmoticonUsage.all;
}
