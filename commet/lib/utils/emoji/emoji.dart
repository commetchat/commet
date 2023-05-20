import 'dart:core';

import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/emoji_matcher.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';

import '../text_utils.dart';

abstract class Emoji {
  ImageProvider get image;
  String? get shortcode;

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
      return WidgetSpan(
          child: EmojiWidget(
        UnicodeEmoji(matchedText),
        height: style != null && style.fontSize != null
            ? style.fontSize
            : emojiHeight,
      ));
    }));
  }
}
