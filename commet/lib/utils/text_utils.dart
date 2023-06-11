import 'dart:math';

import 'package:commet/utils/emoji/emoticon.dart';
import 'package:flutter/material.dart';
import '../ui/atoms/rich_text/spans/link.dart';
import 'emoji/emoji_matcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart' as material;

final _urlRegex = RegExp(
  r'(?:(?:https?|ftp|file):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[A-Z0-9+&@#/%=~_|$])',
  caseSensitive: false,
  dotAll: true,
);

enum NewPasswordResult { valid, tooShort, noNumbers, noSymbols, noMixedCase }

class TextUtils {
  static List<InlineSpan> formatString(String text,
      {bool allowBigEmoji = false, TextStyle? style}) {
    bool bigEmoji = allowBigEmoji && shouldDoBigEmoji(text);
    List<InlineSpan> span = Emoticon.emojifyString(text,
        emojiHeight: bigEmoji ? 48 : 20, style: style);
    span = linkifySpan(span, style);

    return span;
  }

  static List<InlineSpan> formatRichText(List<InlineSpan> spans,
      {TextStyle? style}) {
    spans = Emoticon.emojify(spans);
    spans = linkifySpan(spans, style);
    return spans;
  }

  static List<InlineSpan> linkifySpan(List<InlineSpan> span, TextStyle? style) {
    return formatSpan(span, (text, _) => linkifyString(text, style));
  }

  static bool isRtl(String text, {bool isHtml = false}) {
    return intl.Bidi.detectRtlDirectionality(text, isHtml: isHtml);
  }

  static Widget manageRtlSpan(String text, List<InlineSpan> spans,
      {bool isHtml = false}) {
    bool rtl = isRtl(text, isHtml: isHtml);
    return SizedBox(
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
        return LinkSpan.create(matchedText,
            destination: Uri.tryParse(matchedText), style: style);
      },
    );
  }

  static List<InlineSpan> formatSpan(List<InlineSpan> span,
      List<InlineSpan> Function(String text, TextStyle? style) formatter) {
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

  static List<InlineSpan> formatMatches(
      Iterable<RegExpMatch> matches, String text,
      {required InlineSpan Function(String matchedText, TextStyle? theme)
          builder,
      TextStyle? style}) {
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

  static NewPasswordResult isValidPassword(
    String password, {
    bool forceDigits = false,
    int? forceLength,
    bool forceSpecialCharacter = false,
  }) {
    if (forceLength != null) {
      if (password.length < forceLength) return NewPasswordResult.tooShort;
    }

    if (forceDigits) {
      if (!password.characters.any((char) => int.tryParse(char) != null)) {
        return NewPasswordResult.noNumbers;
      }
    }

    if (forceSpecialCharacter) {
      if (!password.characters.any(
          (char) => ("!@#\$%^&*()_+`{}|:\"<>?/.,';][=-\\").contains(char))) {
        return NewPasswordResult.noSymbols;
      }
    }

    return NewPasswordResult.valid;
  }

  static String timestampToLocalizedTime(DateTime time) {
    var difference = DateTime.now().difference(time);

    if (difference.inDays == 0) {
      return intl.DateFormat(intl.DateFormat.HOUR_MINUTE)
          .format(time.toLocal());
    }

    if (difference.inDays < 365) {
      return intl.DateFormat(intl.DateFormat.MONTH_WEEKDAY_DAY)
          .format(time.toLocal());
    }

    return intl.DateFormat(intl.DateFormat.YEAR_MONTH_WEEKDAY_DAY)
        .format(time.toLocal());
  }

  static String readableFileSize(num number, {bool base1024 = true}) {
    final base = base1024 ? 1024 : 1000;
    if (number <= 0) return "0";
    final units = ["B", "kB", "MB", "GB", "TB"];
    int digitGroups = (log(number) / log(base)).round();
    // ignore: prefer_interpolation_to_compose_strings
    return intl.NumberFormat("#,##0.#")
            .format(number / pow(base, digitGroups)) +
        " " +
        units[digitGroups];
  }
}
