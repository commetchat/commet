import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

class ThemeLightColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 245, 245, 245);
  static const Color primary = Color.fromARGB(255, 106, 141, 255);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);
  static const Color secondary = Color.fromARGB(255, 90, 90, 90);
  static const Color surfaceLow1 = Color.fromARGB(255, 245, 245, 245);
  static const Color surfaceLow2 = Color.fromARGB(255, 240, 240, 240);
  static const Color surfaceLow3 = Color.fromARGB(255, 235, 235, 235);
  static const Color surfaceLow4 = Color.fromARGB(255, 230, 230, 230);
  static const Color highlightColor = Colors.white;
  static const Color onSurface = Colors.black;
  static const Color outlineColor = Color.fromARGB(48, 92, 92, 92);
}

class ThemeLight {
  static ThemeData get theme => ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeLightColors.surfaceHigh1,
            surfaceLow1: ThemeLightColors.surfaceLow1,
            surfaceLow2: ThemeLightColors.surfaceLow2,
            surfaceLow3: ThemeLightColors.surfaceLow3,
            surfaceLow4: ThemeLightColors.surfaceLow4,
            highlight: ThemeLightColors.highlightColor,
            outline: ThemeLightColors.outlineColor),
        ThemeSettings(frosted: false)
      ],
      colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 106, 141, 255),
          secondary: ThemeLightColors.secondary,
          surface: ThemeLightColors.surface,
          background: ThemeLightColors.surfaceLow4,
          error: const Color.fromARGB(255, 255, 91, 91),
          onPrimary: ThemeLightColors.onSurface,
          onSecondary: ThemeLightColors.onSurface,
          onSurface: ThemeLightColors.onSurface,
          onBackground: ThemeLightColors.onSurface,
          onError: Colors.white,
          brightness: Brightness.light,
          shadow: Colors.black.withAlpha(52)),
      sliderTheme: SliderThemeData(
          inactiveTrackColor: ThemeLightColors.primary.withAlpha(100)),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeLightColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll(ThemeLightColors.primary),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ))),
      iconTheme: const IconThemeData(color: ThemeLightColors.secondary),
      dividerColor: ThemeLightColors.outlineColor,
      dividerTheme:
          const DividerThemeData(color: ThemeLightColors.outlineColor),
      dialogTheme: const DialogTheme(
          backgroundColor: ThemeLightColors.surface, shadowColor: Colors.black),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.black12),
        foregroundColor:
            const MaterialStatePropertyAll<Color>(ThemeLightColors.secondary),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
