import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

class ThemeLightColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 245, 245, 245);
  static const Color primary = Color.fromARGB(255, 106, 141, 255);
  static const Color surface = Color.fromARGB(255, 245, 250, 251);
  static const Color surfaceContainer = Color.fromARGB(255, 233, 239, 240);
  static const Color surfaceContainerLow = Color.fromARGB(255, 239, 245, 246);
  static const Color surfaceContainerLowest =
      Color.fromARGB(255, 255, 255, 255);
  static const Color surfaceContainerHigh = Color.fromARGB(255, 227, 233, 234);
  static const Color surfaceContainerHighest =
      Color.fromARGB(255, 222, 227, 229);

  static const Color secondary = Color.fromARGB(255, 90, 90, 90);
  static const Color surfaceLow1 = Color.fromARGB(255, 245, 245, 245);
  static const Color surfaceLow2 = Color.fromARGB(255, 240, 240, 240);
  static const Color surfaceLow3 = Color.fromARGB(255, 235, 235, 235);
  static const Color surfaceLow4 = Color.fromARGB(255, 230, 230, 230);
  static const Color highlightColor = Colors.white30;
  static const Color onSurface = Colors.black;
  static const Color outlineColor = Color.fromARGB(48, 92, 92, 92);
}

class ThemeLight {
  static ThemeData get theme => ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: "RobotoCustom",
      fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
      extensions: const <ThemeExtension<dynamic>>[
        ThemeSettings(frosted: false)
      ],
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
          primaryContainer: ThemeLightColors.primary,
          onPrimaryContainer: Colors.white,
          primary: ThemeLightColors.primary),
      shadowColor: Colors.black.withAlpha(100),
      sliderTheme: SliderThemeData(
          inactiveTrackColor: ThemeLightColors.primary.withAlpha(100)),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeLightColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ))),
      iconTheme: const IconThemeData(color: ThemeLightColors.secondary),
      dividerColor: ThemeLightColors.outlineColor,
      dialogBackgroundColor: ThemeLightColors.surface,
      dividerTheme:
          const DividerThemeData(color: ThemeLightColors.outlineColor),
      dialogTheme: const DialogTheme(
          backgroundColor: ThemeLightColors.surface, shadowColor: Colors.black),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.black12),
        foregroundColor:
            const WidgetStatePropertyAll<Color>(ThemeLightColors.secondary),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
