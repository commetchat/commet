import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class ThemeDarkColors {
  static const Color surfaceHigh1 = Color.fromARGB(255, 47, 51, 55);
  static const Color secondary = Color.fromARGB(255, 128, 128, 128);
  static const Color surface = Color.fromARGB(255, 43, 46, 49);
  static const Color surfaceLow1 = Color.fromARGB(255, 38, 41, 44);
  static const Color surfaceLow2 = Color.fromARGB(255, 30, 34, 37);
  static const Color surfaceLow3 = Color.fromARGB(255, 25, 28, 31);
  static const Color surfaceLow4 = Color.fromARGB(255, 19, 21, 22);
  static const Color onSurface = Colors.white;
  static const Color highlightColor = Colors.white10;
}

class ThemeDark {
  static ThemeData get theme => ThemeData(
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[
        ExtraColors(
            surfaceHigh1: ThemeDarkColors.surfaceHigh1,
            surfaceLow1: ThemeDarkColors.surfaceLow1,
            surfaceLow2: ThemeDarkColors.surfaceLow2,
            surfaceLow3: ThemeDarkColors.surfaceLow3,
            surfaceLow4: ThemeDarkColors.surfaceLow4,
            highlight: ThemeDarkColors.highlightColor),
        ThemeSettings(frosted: false),
      ],
      colorScheme: ColorScheme(
        primary: Color.fromARGB(255, 106, 141, 255),
        secondary: Colors.green,
        surface: ThemeDarkColors.surface,
        background: ThemeDarkColors.surfaceLow4,
        error: Color.fromARGB(255, 255, 63, 63),
        onPrimary: Colors.white,
        onSecondary: ThemeDarkColors.onSurface,
        onSurface: Colors.white,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: ThemeDarkColors.surface,
      ),
      canvasColor: ThemeDarkColors.surface,
      iconTheme: IconThemeData(color: ThemeDarkColors.secondary),
      shadowColor: Colors.black.withAlpha(100),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ))),
      sliderTheme: SliderThemeData(thumbColor: ThemeDarkColors.onSurface),
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
