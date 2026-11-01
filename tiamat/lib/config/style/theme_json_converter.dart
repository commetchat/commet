import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiamat/config/config.dart';
import 'package:path/path.dart' as path;
import 'package:tiamat/config/custom_theme/custom_theme.dart';

class ThemeJsonConverter {
  static Future<ThemeData?> fromJson(
      Map<String, dynamic> json, File? file) async {
    var theme = CustomTheme.fromJson(json);

    var defaultTheme = switch (theme.base) {
      "dark" => ThemeDark.theme,
      "light" => ThemeLight.theme,
      "you_light" => await ThemeYou.theme(Brightness.light),
      "you_dark" => await ThemeYou.theme(Brightness.dark),
      _ => ThemeDark.theme,
    };

    var colorScheme = defaultTheme.colorScheme;

    if (theme.seed != null) {
      DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot;

      if (theme.dynamicSchemeVariant != null) {
        try {
          variant =
              DynamicSchemeVariant.values.byName(theme.dynamicSchemeVariant!);
        } catch (_) {}
      }

      colorScheme = ColorScheme.fromSeed(
          seedColor: theme.seed!,
          brightness: defaultTheme.brightness,
          dynamicSchemeVariant: variant);
    }

    var extraColors = defaultTheme.extension<ExtraColors>();
    var themeSettings = defaultTheme.extension<ThemeSettings>();
    var themeTextures = defaultTheme.extension<PanelTextures>();
    var borders = defaultTheme.extension<CustomThemeBorders>();

    var cols = theme;
    colorScheme = colorScheme.copyWith(
      primary: cols.getColor("primary"),
      onPrimary: cols.getColor("onPrimary"),
      primaryContainer: cols.getColor("primaryContainer"),
      onPrimaryContainer: cols.getColor("onPrimaryContainer"),
      primaryFixed: cols.getColor("primaryFixed"),
      primaryFixedDim: cols.getColor("primaryFixedDim"),
      onPrimaryFixed: cols.getColor("onPrimaryFixed"),
      onPrimaryFixedVariant: cols.getColor("onPrimaryFixedVariant"),
      secondary: cols.getColor("secondary"),
      onSecondary: cols.getColor("onSecondary"),
      secondaryContainer: cols.getColor("secondaryContainer"),
      onSecondaryContainer: cols.getColor("onSecondaryContainer"),
      secondaryFixed: cols.getColor("secondaryFixed"),
      secondaryFixedDim: cols.getColor("secondaryFixedDim"),
      onSecondaryFixed: cols.getColor("onSecondaryFixed"),
      onSecondaryFixedVariant: cols.getColor("onSecondaryFixedVariant"),
      tertiary: cols.getColor("tertiary"),
      onTertiary: cols.getColor("onTertiary"),
      tertiaryContainer: cols.getColor("tertiaryContainer"),
      onTertiaryContainer: cols.getColor("onTertiaryContainer"),
      tertiaryFixed: cols.getColor("tertiaryFixed"),
      tertiaryFixedDim: cols.getColor("tertiaryFixedDim"),
      onTertiaryFixed: cols.getColor("onTertiaryFixed"),
      onTertiaryFixedVariant: cols.getColor("onTertiaryFixedVariant"),
      error: cols.getColor("error"),
      onError: cols.getColor("onError"),
      errorContainer: cols.getColor("errorContainer"),
      onErrorContainer: cols.getColor("onErrorContainer"),
      outline: cols.getColor("outline"),
      outlineVariant: cols.getColor("outlineVariant"),
      surface: cols.getColor("surface"),
      onSurface: cols.getColor("onSurface"),
      surfaceDim: cols.getColor("surfaceDim"),
      surfaceBright: cols.getColor("surfaceBright"),
      surfaceContainerLowest: cols.getColor("surfaceContainerLowest"),
      surfaceContainerLow: cols.getColor("surfaceContainerLow"),
      surfaceContainer: cols.getColor("surfaceContainer"),
      surfaceContainerHigh: cols.getColor("surfaceContainerHigh"),
      surfaceContainerHighest: cols.getColor("surfaceContainerHighest"),
      onSurfaceVariant: cols.getColor("onSurfaceVariant"),
      inverseSurface: cols.getColor("inverseSurface"),
      onInverseSurface: cols.getColor("onInverseSurface"),
      inversePrimary: cols.getColor("inversePrimary"),
      shadow: cols.getColor("shadow"),
      scrim: cols.getColor("scrim"),
      surfaceTint: cols.getColor("surfaceTint"),
    );

    var codeHighlight = cols.getColor("codeHighlight");
    var linkColor = cols.getColor("links");

    FoundationSettings? foundation = theme.foundation != null
        ? FoundationSettings(
            settings: theme.foundation!, rootDirectory: file!.parent.path)
        : null;

    extraColors = extraColors?.copyWith(
        codeHighlight: codeHighlight, linkColor: linkColor) as ExtraColors;

    if (file != null) {
      themeTextures = theme.textures != null
          ? PanelTextures(theme.textures!, file.parent.path)
          : null;
    }

    GlassSettings? glassSettings;

    if (theme.glass != null) {
      glassSettings = GlassSettings(glass: theme.glass!);
    }

    if (theme.borders != null) {
      borders = CustomThemeBorders(theme.borders!);
    }

    var data = defaultTheme.copyWith(
        colorScheme: colorScheme,
        extensions: <ThemeExtension?>[
          themeSettings,
          extraColors,
          foundation,
          themeTextures,
          glassSettings,
          borders,
        ].nonNulls);

    return data;
  }

  static ShadowSettings? loadShadows(Map<String, dynamic> json) {
    var data = json.tryGet<List<dynamic>>("shadows");
    if (data == null) {
      return null;
    }

    List<BoxShadow> shadows = List.empty(growable: true);

    for (var entry in data) {
      if (entry is! Map<String, dynamic>) {
        print("Entry was not a map, continuing");
        continue;
      }

      var color = entry.tryGetColor("color");
      var blurRadius = entry.tryGetDouble("blurRadius");
      var spreadRadius = entry.tryGetDouble("spreadRadius");

      var offsetValues = entry.tryGet<List<dynamic>>("offset");
      Offset? offset;
      if (offsetValues != null) {
        var values = List<num>.from(offsetValues);
        if (values.length >= 2) {
          offset = Offset(values[0].toDouble(), values[1].toDouble());
        }
      }

      shadows.add(BoxShadow(
          color: color ?? Colors.black,
          offset: offset ?? Offset.zero,
          spreadRadius: spreadRadius ?? 0,
          blurRadius: blurRadius ?? 0));
    }
    if (shadows.isNotEmpty) {
      return ShadowSettings(shadows);
    } else {
      return null;
    }
  }
}

extension ThemeUtils on Map {
  T? tryGet<T>(String key) {
    if (containsKey(key) == false) {
      return null;
    }

    var value = this[key];
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  double? tryGetDouble(String key) {
    var d = tryGet<num>(key);
    return d?.toDouble();
  }

  Color? tryGetColor(String key) {
    var hexString = tryGet<String>(key);
    if (hexString == null) return null;

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
