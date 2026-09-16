import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ThemeCommon {
  static List<String>? fontFamilyFallback() {
    // Apple does not render emoji with the default font
    // instead use the system-available emoji font.
    if (!kIsWeb && (Platform.isMacOS || Platform.isIOS)) {
      return ["Apple Color Emoji"];
    }
    const fonts = ["EmojiFont"];
    return fonts;
  }
}
