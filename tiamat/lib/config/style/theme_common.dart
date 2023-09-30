import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ThemeCommon {
  static List<String>? fontFamilyFallback() {
    const fonts = ["EmojiFont"];

    // Platform.isWindows isnt available on web so just jump out early here!
    if (kIsWeb) return fonts;

    // Windows doesnt support our current emoji font :(
    if (Platform.isWindows) return null;

    return fonts;
  }
}
