import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/config/style/theme_light.dart';

class ThemeYou {
  static Future<ThemeData> theme(Brightness brightness) async {
    var palette = await DynamicColorPlugin.getCorePalette();
    ColorScheme? scheme;

    if (palette != null) {
      scheme = palette.toColorScheme(brightness: brightness);
    }

    if (scheme == null) {
      var color = await DynamicColorPlugin.getAccentColor();
      if (color != null) {
        scheme = ColorScheme.fromSeed(seedColor: color, brightness: brightness);
      }
    }

    return ThemeData(
        brightness: brightness,
        useMaterial3: true,
        fontFamily: "RobotoCustom",
        extensions: [ThemeSettings()],
        fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
        colorScheme: scheme,
        shadowColor: Colors.black.withAlpha(100),
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
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ))),
        iconTheme: const IconThemeData(color: ThemeLightColors.secondary),
        dividerColor: ThemeLightColors.outlineColor,
        dialogBackgroundColor: ThemeLightColors.surface,
        dividerTheme:
            const DividerThemeData(color: ThemeLightColors.outlineColor),
        dialogTheme: const DialogTheme(
            backgroundColor: ThemeLightColors.surface,
            shadowColor: Colors.black),
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
}
