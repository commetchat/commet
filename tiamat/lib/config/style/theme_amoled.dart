import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'dart:io' show Platform;

class ThemeAmoledColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 30, 30, 30);
  static const Color secondary = Color.fromARGB(255, 150, 150, 150);
  static const Color primary = Color.fromARGB(255, 106, 141, 255);
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
  static ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      fontFamily: "RobotoCustom",
      fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeAmoledColors.surfaceHigh1,
            surfaceLow1: ThemeAmoledColors.surfaceLow1,
            surfaceLow2: ThemeAmoledColors.surfaceLow2,
            surfaceLow3: ThemeAmoledColors.surfaceLow3,
            surfaceLow4: ThemeAmoledColors.surfaceLow4,
            highlight: ThemeAmoledColors.highlightColor,
            outline: ThemeAmoledColors.outlineColor,
            codeHighlight: Color(0xffc678dd)),
        ThemeSettings(frosted: false),
      ],
      colorScheme: ColorScheme(
          primary: Color.fromARGB(255, 113, 146, 255),
          secondary: ThemeAmoledColors.secondary,
          surface: ThemeAmoledColors.surface,
          background: ThemeAmoledColors.surfaceLow4,
          error: Color.fromARGB(255, 255, 124, 124),
          onPrimary: Colors.white,
          onSecondary: ThemeAmoledColors.onSurface,
          onSurface: Colors.white,
          onBackground: Colors.black,
          onError: Colors.white,
          brightness: Brightness.dark,
          outline: ThemeAmoledColors.surfaceHigh1),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeAmoledColors.surface,
      ),
      canvasColor: ThemeAmoledColors.surface,
      iconTheme: const IconThemeData(color: ThemeAmoledColors.secondary),
      shadowColor: Colors.black.withAlpha(100),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll(ThemeAmoledColors.primary),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ))),
      dividerTheme:
          const DividerThemeData(color: ThemeAmoledColors.surfaceHigh1),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: ThemeAmoledColors.primary.withAlpha(100),
      ),
      dialogTheme: const DialogTheme(
          backgroundColor: ThemeAmoledColors.surface,
          shadowColor: Colors.black),
      dialogBackgroundColor: ThemeAmoledColors.highlightColor,
      switchTheme: const SwitchThemeData(
          thumbColor: MaterialStatePropertyAll(ThemeAmoledColors.secondary)),
      dividerColor: ThemeAmoledColors.outlineColor,
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.white10),
        foregroundColor: MaterialStatePropertyAll<Color>(Colors.grey.shade300),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(
            color: Colors.white,
          ),
        ),
      )));
}
