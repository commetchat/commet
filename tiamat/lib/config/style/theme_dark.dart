import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'dart:io' show Platform;

class ThemeDarkColors {
  static const Color surfaceContainerHigh = Color.fromARGB(255, 47, 51, 55);
  static const Color secondary = Color.fromARGB(255, 128, 128, 128);
  static const Color primary = Color.fromARGB(255, 106, 141, 255);
  static const Color surface = Color.fromARGB(255, 43, 46, 49);
  static const Color surfaceContainer = Color.fromARGB(255, 38, 41, 44);
  static const Color surfaceContainerLow = Color.fromARGB(255, 30, 34, 37);
  static const Color surfaceLow3 = Color.fromARGB(255, 25, 28, 31);
  static const Color surfaceContainerLowest = Color.fromARGB(255, 19, 21, 22);
  static const Color onSurface = Colors.white;
  static const Color highlightColor = Colors.white10;
  static const Color outlineColor = Color.fromARGB(255, 30, 34, 37);
}

class ThemeDark {
  static ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      fontFamily: "RobotoCustom",
      fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
      useMaterial3: true,
      extensions: [
        ThemeSettings(),
      ],
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 106, 141, 255),
          secondary: ThemeDarkColors.secondary,
          surface: ThemeDarkColors.surface,
          surfaceContainer: ThemeDarkColors.surfaceContainer,
          surfaceContainerLow: ThemeDarkColors.surfaceContainerLow,
          surfaceContainerLowest: ThemeDarkColors.surfaceContainerLowest,
          surfaceContainerHigh: ThemeDarkColors.surfaceContainerHigh,
          surfaceContainerHighest: ThemeDarkColors.surfaceContainerHigh,
          primaryContainer: ThemeDarkColors.primary,
          onPrimaryContainer: Colors.white,
          onPrimary: Colors.white,
          onSecondary: ThemeDarkColors.onSurface,
          onSurface: Colors.white,
          brightness: Brightness.dark,
          outline: ThemeDarkColors.surfaceContainerHigh),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeDarkColors.surface,
      ),
      canvasColor: ThemeDarkColors.surface,
      iconTheme: const IconThemeData(color: ThemeDarkColors.secondary),
      shadowColor: Colors.black.withAlpha(100),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ))),
      dividerTheme:
          const DividerThemeData(color: ThemeDarkColors.surfaceContainerHigh),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: ThemeDarkColors.primary.withAlpha(100),
      ),
      dialogTheme: const DialogTheme(
          backgroundColor: ThemeDarkColors.surface, shadowColor: Colors.black),
      switchTheme: const SwitchThemeData(
          thumbColor: WidgetStatePropertyAll(ThemeDarkColors.secondary)),
      dividerColor: ThemeDarkColors.outlineColor,
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.white10),
        foregroundColor: WidgetStatePropertyAll<Color>(Colors.grey.shade300),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            color: Colors.white,
          ),
        ),
      )));
}
