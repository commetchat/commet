import 'package:commet/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';

import 'theme_dark.dart';

class ThemeGlass {
  ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeDarkColors.surfaceHigh1,
            surfaceLow1: ThemeDarkColors.surfaceLow1,
            surfaceLow2: ThemeDarkColors.surfaceLow2,
            surfaceLow3: ThemeDarkColors.surfaceLow3,
            surfaceLowest: ThemeDarkColors.surfaceLowest,
            highlight: ThemeDarkColors.highlightColor),
        ThemeSettings(frosted: true),
      ],
      colorScheme: ColorScheme(
        primary: Colors.blue,
        secondary: Colors.green,
        surface: Colors.transparent,
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
      iconTheme: IconThemeData(color: ThemeDarkColors.secondary),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.transparent),
        overlayColor: const MaterialStatePropertyAll<Color>(Colors.white10),
        foregroundColor: MaterialStatePropertyAll<Color>(Colors.grey.shade300),
        shape:
            MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const MaterialStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
      )));
}
