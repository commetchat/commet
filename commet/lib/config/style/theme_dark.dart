import 'package:commet/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

class ThemeDark {
  ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceLow: Color.fromARGB(255, 38, 41, 44),
            surfaceExtraLow: Color.fromARGB(255, 22, 24, 26),
            surfaceLowest: Color.fromARGB(255, 15, 17, 18))
      ],
      colorScheme: ColorScheme(
        primary: Colors.blue,
        secondary: Colors.green,
        surface: Color.fromARGB(255, 47, 51, 55),
        background: Colors.grey.shade500,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.white10),
        foregroundColor: MaterialStatePropertyAll<Color>(Colors.grey.shade300),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
