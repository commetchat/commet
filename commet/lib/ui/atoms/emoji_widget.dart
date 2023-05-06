import 'package:flutter/widgets.dart';

final _u200D = String.fromCharCode(0x200D);

final _uFE0Fg = RegExp(
  r'\uFE0F',
  unicode: true,
);

class EmojiWidget extends StatelessWidget {
  static String toUnicode(String rawText) => _toCodePoint(
        /// Converts emoji to unicode 😀 => "1F600"
        !rawText.contains(_u200D) ? rawText.replaceAll(_uFE0Fg, '') : rawText,
      );

  static String _toCodePoint(String input, {String sep = '-'}) {
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

  late final String unicode;
  late final double? height;

  EmojiWidget(String emoji, {super.key, this.height = 24}) {
    unicode = toUnicode(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      width: height,
      height: height,
      image: AssetImage("assets/twemoji/assets/72x72/$unicode.png"),
    );
  }
}
