import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ThemeCommon {
  static List<String>? fontFamilyFallback() {
    if (!kIsWeb && (Platform.isMacOS || Platform.isIOS)) {
      return ["Apple Color Emoji"];
    }
    const fonts = ["EmojiFont"];
    return fonts;
  }
}
