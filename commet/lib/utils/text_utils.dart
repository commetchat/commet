import 'package:commet/utils/emoji/emoji.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../ui/atoms/rich_text/spans/link.dart';
import 'emoji/emoji_matcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart' as material;

final _urlRegex = RegExp(
  r'([\w+]+\:\/\/)?([\w\d-]+\.)*[\w-]+[\.\:]\w+([\/\?\=\&\#.]?[\w-]+)*\/?',
  caseSensitive: false,
  dotAll: true,
);

class TextUtils {
  static List<InlineSpan> formatString(String text, {bool allowBigEmoji = false, TextStyle? style}) {
    bool bigEmoji = allowBigEmoji && shouldDoBigEmoji(text);
    List<InlineSpan> span = Emoji.emojifyString(text, emojiHeight: bigEmoji ? 48 : 20, style: style);
    span = linkifySpan(span, style);

    return span;
  }

  static List<InlineSpan> formatRichText(List<InlineSpan> spans, {TextStyle? style}) {
    spans = Emoji.emojify(spans);
    spans = linkifySpan(spans, style);
    return spans;
  }

  static List<InlineSpan> linkifySpan(List<InlineSpan> span, TextStyle? style) {
    return formatSpan(span, (text, _) => linkifyString(text, style));
  }

  static bool isRtl(String text, {bool isHtml = false}) {
    return intl.Bidi.detectRtlDirectionality(text, isHtml: isHtml);
  }

  static Widget manageRtlSpan(String text, List<InlineSpan> spans, {bool isHtml = false}) {
    bool rtl = isRtl(text, isHtml: isHtml);
    return Container(
        width: double.infinity,
        child: material.Text.rich(
          material.TextSpan(children: spans),
          textAlign: rtl ? TextAlign.right : TextAlign.left,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ));
  }

  static List<InlineSpan> linkifyString(String text, TextStyle? style) {
    var matches = _urlRegex.allMatches(text);
    return formatMatches(
      matches,
      text,
      style: style,
      builder: (matchedText, _) {
        return LinkSpan.create(matchedText, destination: Uri.tryParse(matchedText), style: style);
      },
    );
  }

  static List<InlineSpan> formatSpan(
      List<InlineSpan> span, List<InlineSpan> Function(String text, TextStyle? style) formatter) {
    for (int i = span.length - 1; i >= 0; i--) {
      var item = span[i];
      if (item is TextSpan) {
        var spans = formatter(item.text!, item.style);
        span.removeAt(i);
        span.insertAll(i, spans);
      }
    }
    return span;
  }

  static List<InlineSpan> formatMatches(Iterable<RegExpMatch> matches, String text,
      {required InlineSpan Function(String matchedText, TextStyle? theme) builder, TextStyle? style}) {
    if (matches.isEmpty) return [TextSpan(text: text, style: style)];

    List<InlineSpan> span = List.empty(growable: true);
    for (int i = 0; i < matches.length; i++) {
      var match = matches.elementAt(i);

      String? pre;

      if (i == 0 && match.start > 0) {
        pre = text.substring(0, match.start);
      } else if (i > 0) {
        var start = match.start;
        var end = matches.elementAt(i - 1).end;

        if (start != end) {
          var previous = matches.elementAt(i - 1);
          pre = text.substring(previous.end, match.start);
        }
      }

      if (pre != null) {
        span.add(TextSpan(text: pre, style: style));
      }

      span.add(builder(text.substring(match.start, match.end), style));
    }

    if (matches.last.end != text.length) {
      span.add(TextSpan(text: text.substring(matches.last.end), style: style));
    }

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
