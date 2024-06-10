import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiamat/config/config.dart';
import 'package:path/path.dart' as path;

class ThemeJsonConverter {
  static ThemeData? fromJson(Map<String, dynamic> json, File? file) {
    var base = json.tryGet<String>("base");

    var defaultTheme = switch (base) {
      "dark" => ThemeDark.theme,
      "light" => ThemeLight.theme,
      _ => ThemeDark.theme,
    };

    var themeSettings = defaultTheme.extension<ThemeSettings>();

    var settings = json.tryGet<Map<String, dynamic>>("settings");

    ThemeExtension<GlassSettings>? glass;

    if (json.containsKey("glass")) {
      var data = json.tryGet<Map<String, dynamic>>("glass");
      if (data != null) {
        glass = const GlassSettings().copyWith(
          surfaceSigma: data.tryGetDouble("surfaceSigma"),
          surfaceOpacity: data.tryGetDouble("surfaceOpacity"),
          surfaceDimSigma: data.tryGetDouble("surfaceDimSigma"),
          surfaceDimOpacity: data.tryGetDouble("surfaceDimOpacity"),
          surfaceContainerLowestSigma:
              data.tryGetDouble("surfaceContainerLowestSigma"),
          surfaceContainerLowestOpacity:
              data.tryGetDouble("surfaceContainerLowestOpacity"),
          surfaceContainerLowSigma:
              data.tryGetDouble("surfaceContainerLowSigma"),
          surfaceContainerLowOpacity:
              data.tryGetDouble("surfaceContainerLowOpacity"),
          surfaceContainerSigma: data.tryGetDouble("surfaceContainerSigma"),
          surfaceContainerOpacity: data.tryGetDouble("surfaceContainerOpacity"),
          surfaceContainerHighSigma:
              data.tryGetDouble("surfaceContainerHighSigma"),
          surfaceContainerHighOpacity:
              data.tryGetDouble("surfaceContainerHighOpacity"),
          surfaceContainerHighestSigma:
              data.tryGetDouble("surfaceContainerHighestSigma"),
          surfaceContainerHighestOpacity:
              data.tryGetDouble("surfaceContainerHighestOpacity"),
        );
      }
    }

    themeSettings = ThemeSettings(
      caulkBorders: settings?.tryGet<bool>("caulkBorders") ?? false,
      caulkStrokeThickness: settings?.tryGetDouble("caulkStrokeThickness") ?? 0,
      caulkBorderRadius: settings?.tryGetDouble("caulkBorderRadius") ?? 0,
      caulkPadding: settings?.tryGetDouble("caulkPadding") ?? 0,
      shadowBlurRadius: settings?.tryGetDouble("shadowBlurRadius") ?? 0,
    );

    var schemeData = json.tryGet<Map<String, dynamic>>("colorScheme");

    var colorScheme = defaultTheme.colorScheme;
    var seedColor = schemeData?.tryGetColor("seed");

    if (seedColor != null) {
      DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot;

      var variantJson = schemeData?.tryGet<String>("dynamicSchemeVariant");
      if (variantJson != null) {
        try {
          variant = DynamicSchemeVariant.values.byName(variantJson);
        } catch (_) {}
      }

      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: defaultTheme.brightness,
        dynamicSchemeVariant: variant,
        primary: schemeData?.tryGetColor("primary"),
        onPrimary: schemeData?.tryGetColor("onPrimary"),
        primaryContainer: schemeData?.tryGetColor("primaryContainer"),
        onPrimaryContainer: schemeData?.tryGetColor("onPrimaryContainer"),
        primaryFixed: schemeData?.tryGetColor("primaryFixed"),
        primaryFixedDim: schemeData?.tryGetColor("primaryFixedDim"),
        onPrimaryFixed: schemeData?.tryGetColor("onPrimaryFixed"),
        onPrimaryFixedVariant: schemeData?.tryGetColor("onPrimaryFixedVariant"),
        secondary: schemeData?.tryGetColor("secondary"),
        onSecondary: schemeData?.tryGetColor("onSecondary"),
        secondaryContainer: schemeData?.tryGetColor("secondaryContainer"),
        onSecondaryContainer: schemeData?.tryGetColor("onSecondaryContainer"),
        secondaryFixed: schemeData?.tryGetColor("secondaryFixed"),
        secondaryFixedDim: schemeData?.tryGetColor("secondaryFixedDim"),
        onSecondaryFixed: schemeData?.tryGetColor("onSecondaryFixed"),
        onSecondaryFixedVariant:
            schemeData?.tryGetColor("onSecondaryFixedVariant"),
        tertiary: schemeData?.tryGetColor("tertiary"),
        onTertiary: schemeData?.tryGetColor("onTertiary"),
        tertiaryContainer: schemeData?.tryGetColor("tertiaryContainer"),
        onTertiaryContainer: schemeData?.tryGetColor("onTertiaryContainer"),
        tertiaryFixed: schemeData?.tryGetColor("tertiaryFixed"),
        tertiaryFixedDim: schemeData?.tryGetColor("tertiaryFixedDim"),
        onTertiaryFixed: schemeData?.tryGetColor("onTertiaryFixed"),
        onTertiaryFixedVariant:
            schemeData?.tryGetColor("onTertiaryFixedVariant"),
        error: schemeData?.tryGetColor("error"),
        onError: schemeData?.tryGetColor("onError"),
        errorContainer: schemeData?.tryGetColor("errorContainer"),
        onErrorContainer: schemeData?.tryGetColor("onErrorContainer"),
        outline: schemeData?.tryGetColor("outline"),
        outlineVariant: schemeData?.tryGetColor("outlineVariant"),
        surface: schemeData?.tryGetColor("surface"),
        onSurface: schemeData?.tryGetColor("onSurface"),
        surfaceDim: schemeData?.tryGetColor("surfaceDim"),
        surfaceBright: schemeData?.tryGetColor("surfaceBright"),
        surfaceContainerLowest:
            schemeData?.tryGetColor("surfaceContainerLowest"),
        surfaceContainerLow: schemeData?.tryGetColor("surfaceContainerLow"),
        surfaceContainer: schemeData?.tryGetColor("surfaceContainer"),
        surfaceContainerHigh: schemeData?.tryGetColor("surfaceContainerHigh"),
        surfaceContainerHighest:
            schemeData?.tryGetColor("surfaceContainerHighest"),
        onSurfaceVariant: schemeData?.tryGetColor("onSurfaceVariant"),
        inverseSurface: schemeData?.tryGetColor("inverseSurface"),
        onInverseSurface: schemeData?.tryGetColor("onInverseSurface"),
        inversePrimary: schemeData?.tryGetColor("inversePrimary"),
        shadow: schemeData?.tryGetColor("shadow"),
        scrim: schemeData?.tryGetColor("scrim"),
        surfaceTint: schemeData?.tryGetColor("surfaceTint"),
      );
    }

    FoundationSettings foundation =
        loadFoundation(defaultTheme, colorScheme, json, file);

    var data = defaultTheme.copyWith(colorScheme: colorScheme, extensions: [
      themeSettings,
      if (glass != null) glass,
      foundation,
    ]);

    return data;
  }

  static FoundationSettings loadFoundation(ThemeData defaultTheme,
      ColorScheme colorScheme, Map<String, dynamic> json, File? file) {
    FoundationSettings foundation =
        defaultTheme.extension<FoundationSettings>() ??
            FoundationSettings(color: colorScheme.surfaceContainerLowest);

    if (json.containsKey("foundation")) {
      var data = json.tryGet<Map<String, dynamic>>("foundation");
      if (data != null) {
        var image = data.tryGet<Map<String, dynamic>>("image");
        if (image != null && file != null) {
          var imageFile = image.tryGet<String>("file");
          if (imageFile != null) {
            var imagePath = path.join(file.parent.path, imageFile);
            foundation = foundation.copyWith(image: FileImage(File(imagePath)))
                as FoundationSettings;
          }
        }

        try {
          foundation = foundation.copyWith(
            imageFit: image != null
                ? BoxFit.values.byName(image.tryGet<String>("fit")!)
                : null,
          ) as FoundationSettings;
        } catch (_) {}

        try {
          foundation = foundation.copyWith(
            stackFit: image != null
                ? StackFit.values.byName(image.tryGet<String>("stackFit")!)
                : null,
          ) as FoundationSettings;
        } catch (_) {}

        foundation = foundation.copyWith(
            imageAlignment: switch (image?.tryGet<String>("alignment")) {
          "topLeft" => Alignment.topLeft,
          "topCenter" => Alignment.topCenter,
          "topRight" => Alignment.topRight,
          "centerLeft" => Alignment.centerLeft,
          "center" => Alignment.center,
          "centerRight" => Alignment.centerRight,
          "bottomLeft" => Alignment.bottomLeft,
          "bottomCenter" => Alignment.bottomCenter,
          "bottomRight" => Alignment.bottomRight,
          _ => Alignment.center,
        }) as FoundationSettings;

        foundation = foundation.copyWith(color: data.tryGetColor("color"))
            as FoundationSettings;
      }
    }
    return foundation;
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
