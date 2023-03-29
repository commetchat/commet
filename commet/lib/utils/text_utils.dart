import 'package:commet/utils/emoji/emoji.dart';
import 'package:flutter/material.dart';

import 'emoji/emoji_matcher.dart';

class TextUtils {
  static List<InlineSpan> formatString(String text, {bool allowBigEmoji = false}) {
    bool bigEmoji = allowBigEmoji && shouldDoBigEmoji(text);
    List<InlineSpan> span = Emoji.emojifyString(text, emojiHeight: bigEmoji ? 48 : 20);

    return span;
  }

  static bool shouldDoBigEmoji(String text) {
    if (text.characters.length > 10) return false;

    for (var char in text.characters) {
      if (EmojiMatcher.find(char).isEmpty) return false;
    }

    return true;
  }
}
