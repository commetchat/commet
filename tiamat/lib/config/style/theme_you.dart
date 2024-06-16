import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_base.dart';
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

    return ThemeBase.theme(brightness).copyWith(
      brightness: brightness,
      useMaterial3: true,
      extensions: [
        ThemeSettings(),
        if (scheme != null) ExtraColors.fromScheme(scheme)
      ],
      colorScheme: scheme,
    );
  }
}
