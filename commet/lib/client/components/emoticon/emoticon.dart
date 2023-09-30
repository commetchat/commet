import 'dart:core';
import 'package:commet/utils/emoji/emoji_matcher.dart';
import 'package:commet/utils/text_utils.dart';
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

  static List<InlineSpan> emojify(List<InlineSpan> span,
      {double? emojiHeight}) {
    return TextUtils.formatSpan(
        span,
        (text, style) =>
            emojifyString(text, emojiHeight: emojiHeight, style: style));
  }

  static List<InlineSpan> emojifyString(String text,
      {double? emojiHeight, TextStyle? style}) {
    var emojis = EmojiMatcher.find(text);

    return TextUtils.formatMatches(emojis, text, style: style,
        builder: ((matchedText, style) {
      return TextSpan(text: matchedText);
    }));
  }
}
