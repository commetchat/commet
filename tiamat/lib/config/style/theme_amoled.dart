import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_base.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'dart:io' show Platform;

class ThemeAmoledColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 30, 30, 30);
  static const Color secondary = Color.fromARGB(255, 200, 200, 200);
  static const Color primary = Colors.white;
  static const Color surface = Colors.black;
  static const Color surfaceLow1 = Color.fromARGB(255, 10, 10, 10);
  static const Color surfaceLow2 = Color.fromARGB(255, 15, 15, 15);
  static const Color surfaceLow3 = Color.fromARGB(255, 20, 20, 20);
  static const Color surfaceLow4 = Color.fromARGB(255, 25, 25, 25);
  static const Color onSurface = Colors.white;
  static const Color highlightColor = Colors.white10;
  static const Color outlineColor = Color.fromARGB(255, 30, 34, 37);
}

class ThemeAmoled {
  static ThemeData get theme {
    var base = ThemeBase.theme(Brightness.dark);
    return base.copyWith(
      brightness: Brightness.dark,
      extensions: const [
        ThemeSettings(caulkBorders: true, caulkStrokeThickness: 1)
      ],
      colorScheme: const ColorScheme(
          primary: Colors.white,
          secondary: ThemeAmoledColors.secondary,
          secondaryContainer: Color.fromARGB(255, 40, 40, 40),
          surface: ThemeAmoledColors.surface,
          error: Color.fromARGB(255, 255, 124, 124),
          onPrimary: Colors.white,
          onSecondary: ThemeAmoledColors.onSurface,
          onSurface: Colors.white,
          onError: Colors.white,
          tertiaryContainer: Colors.black,
          brightness: Brightness.dark,
          outline: ThemeAmoledColors.surfaceHigh1),
      listTileTheme: base.listTileTheme.copyWith(
        tileColor: ThemeAmoledColors.surface,
      ),
    );
  }
}
