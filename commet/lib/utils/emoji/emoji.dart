import 'dart:core';

import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/emoji_matcher.dart';
import 'package:flutter/material.dart';

class Emoji {
  late ImageProvider image;
  String? shortcode;
  String? unicode;

  Emoji(this.image, {this.shortcode, this.unicode});

  static List<InlineSpan> emojify(List<InlineSpan> spans) {
    for (int i = 0; i < spans.length; i++) {
      var span = spans[i];
      if (span is! TextSpan) continue;
      if (span.text == null) continue;
    }

    return spans;
  }

  static List<InlineSpan> emojifyString(String text, {double? emojiHeight}) {
    var emojis = EmojiMatcher.find(text);

    if (emojis.isEmpty) return [TextSpan(text: text)];

    List<InlineSpan> span = List.empty(growable: true);
    for (int i = 0; i < emojis.length; i++) {
      var emojiMatch = emojis.elementAt(i);

      String? pre;

      if (i == 0 && emojiMatch.start > 0) {
        pre = text.substring(0, emojiMatch.start);
      } else if (i > 0) {
        var start = emojiMatch.start;
        var end = emojis.elementAt(i - 1).end;

        if (start != end) {
          var previous = emojis.elementAt(i - 1);
          pre = text.substring(previous.end, emojiMatch.start);
        }
      }

      if (pre != null) {
        span.add(TextSpan(text: pre));
      }

      span.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 0, 1, 0),
            child: EmojiWidget(
              text.substring(emojiMatch.start, emojiMatch.end),
              height: emojiHeight,
            ),
          )));
    }

    if (emojis.last.end != text.length) {
      span.add(TextSpan(text: text.substring(emojis.last.end)));
    }

    return span;
  }
}
