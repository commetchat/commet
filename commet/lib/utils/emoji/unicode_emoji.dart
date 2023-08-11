import 'package:commet/utils/emoji/emoji.dart';
import 'package:flutter/widgets.dart';

class UnicodeEmoji extends Emoji {
  late ImageProvider _image;
  late String? _shortcode;

  @override
  ImageProvider<Object> get image => _image;

  @override
  String? get shortcode => _shortcode;

  @override
  String get identifier => text;

  String text;

  UnicodeEmoji(this.text, {String? shortcode}) {
    String hexcode = emojiToUnicode(text);
    _image = AssetImage("assets/twemoji/assets/72x72/$hexcode.png");
    _shortcode = shortcode;

    if (!Emoji.knownEmoji.containsKey(identifier)) {
      Emoji.knownEmoji[identifier] = this;
    }
  }

  final _u200D = String.fromCharCode(0x200D);

  final _uFE0Fg = RegExp(
    r'\uFE0F',
    unicode: true,
  );

  String emojiToUnicode(String rawText) => toCodePoint(
        !rawText.contains(_u200D) ? rawText.replaceAll(_uFE0Fg, '') : rawText,
      );

  String toCodePoint(String input, {String sep = '-'}) {
    var r = [], c = 0, p = 0, i = 0;
    while (i < input.length) {
      c = input.codeUnitAt(i++);
      if (p != 0) {
        r.add(
            (0x10000 + ((p - 0xD800) << 10) + (c - 0xDC00)).toRadixString(16));
        p = 0;
      } else if (0xD800 <= c && c <= 0xDBFF) {
        p = c;
      } else {
        r.add(c.toRadixString(16));
      }
    }
    return r.join(sep);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! UnicodeEmoji) {
      return false;
    }

    return other.text == text;
  }

  @override
  int get hashCode {
    return text.hashCode;
  }
}
