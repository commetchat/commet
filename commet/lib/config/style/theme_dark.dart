import 'package:commet/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

class ThemeDarkColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 47, 51, 55);
  static const Color surface = Color.fromARGB(255, 43, 46, 49);
  static const Color surfaceLow1 = Color.fromARGB(255, 38, 41, 44);
  static const Color surfaceLow2 = Color.fromARGB(255, 30, 34, 37);
  static const Color surfaceLow3 = Color.fromARGB(255, 25, 28, 31);
  static const Color surfaceLowest = Color.fromARGB(255, 19, 21, 22);
  static const Color highlightColor = Colors.white10;
}

class ThemeDark {
  ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeDarkColors.surfaceHigh1,
            surfaceLow1: ThemeDarkColors.surfaceLow1,
            surfaceLow2: ThemeDarkColors.surfaceLow2,
            surfaceLow3: ThemeDarkColors.surfaceLow3,
            surfaceLowest: ThemeDarkColors.surfaceLowest,
            highlight: ThemeDarkColors.highlightColor)
      ],
      colorScheme: ColorScheme(
        primary: Colors.blue,
        secondary: Colors.green,
        surface: ThemeDarkColors.surface,
        background: ThemeDarkColors.surfaceLowest,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeDarkColors.surface,
      ),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.white10),
        foregroundColor: MaterialStatePropertyAll<Color>(Colors.grey.shade300),
        shape:
            MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
