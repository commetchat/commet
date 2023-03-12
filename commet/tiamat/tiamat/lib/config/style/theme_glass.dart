import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

import 'theme_dark.dart';

class ThemeGlass {
  static ThemeData get theme {
    return ThemeDark.theme.copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeDarkColors.surfaceHigh1,
            surfaceLow1: ThemeDarkColors.surfaceLow1,
            surfaceLow2: ThemeDarkColors.surfaceLow2,
            surfaceLow3: ThemeDarkColors.surfaceLow3,
            surfaceLow4: ThemeDarkColors.surfaceLow4,
            highlight: ThemeDarkColors.highlightColor),
        ThemeSettings(frosted: true),
      ],
    );
  }
}
