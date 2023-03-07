import 'package:commet/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

class ThemeLightColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 245, 245, 245);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);
  static const Color secondary = Color.fromARGB(255, 90, 90, 90);
  static const Color surfaceLow1 = Color.fromARGB(255, 245, 245, 245);
  static const Color surfaceLow2 = Color.fromARGB(255, 245, 245, 245);
  static const Color surfaceLow3 = Color.fromARGB(255, 245, 245, 245);
  static const Color surfaceLowest = Color.fromARGB(255, 240, 240, 240);
  static const Color highlightColor = Colors.white;
}

class ThemeLight {
  ThemeData get theme => ThemeData(
      brightness: Brightness.light,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeLightColors.surfaceHigh1,
            surfaceLow1: ThemeLightColors.surfaceLow1,
            surfaceLow2: ThemeLightColors.surfaceLow2,
            surfaceLow3: ThemeLightColors.surfaceLow3,
            surfaceLowest: ThemeLightColors.surfaceLowest,
            highlight: ThemeLightColors.highlightColor)
      ],
      colorScheme: ColorScheme(
        primary: Colors.blue,
        secondary: ThemeLightColors.secondary,
        surface: ThemeLightColors.surface,
        background: ThemeLightColors.surfaceLowest,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeLightColors.surface,
      ),
      iconTheme: IconThemeData(color: ThemeLightColors.secondary),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.black12),
        foregroundColor: MaterialStatePropertyAll<Color>(ThemeLightColors.secondary),
        shape:
            MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
