import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_base.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:tiamat/config/style/theme_dark.dart';

class ThemeYou {
  static Future<ThemeData> theme(Brightness brightness) async {
    ColorScheme? scheme;
    scheme = (await DynamicColorPlugin.getColorScheme())?[
        brightness == Brightness.light ? 0 : 1];

    if (scheme == null) {
      var color = await DynamicColorPlugin.getAccentColor();
      if (color != null) {
        scheme = ColorScheme.fromSeed(seedColor: color, brightness: brightness);
      }
    }

    // fallback to default themes if device doesnt support dynamic color
    if (scheme == null) {
      if (brightness == Brightness.dark) {
        return ThemeDark.theme;
      } else {
        return ThemeLight.theme;
      }
    }

    return ThemeBase.theme(scheme!).copyWith(extensions: [
      const ThemeSettings(),
      ExtraColors.fromScheme(scheme),
      FoundationSettings(color: scheme.surfaceDim)
    ]);
  }
}
