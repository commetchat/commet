import 'dart:core';

import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/emoji_matcher.dart';
import 'package:flutter/material.dart';

import '../text_utils.dart';

class Emoji {
  late ImageProvider image;
  String? shortcode;
  String? unicode;

  Emoji(this.image, {this.shortcode, this.unicode});

  static List<InlineSpan> emojify(List<InlineSpan> span, {double? emojiHeight}) {
    return TextUtils.formatSpan(span, (text, style) => emojifyString(text, emojiHeight: emojiHeight, style: style));
  }

  static List<InlineSpan> emojifyString(String text, {double? emojiHeight, TextStyle? style}) {
    var emojis = EmojiMatcher.find(text);

    return TextUtils.formatMatches(emojis, text, style: style, builder: ((matchedText, style) {
      return EmojiWidget(
        matchedText,
        height: style != null && style.fontSize != null ? style.fontSize : emojiHeight,
      );
    }));
  }
}
