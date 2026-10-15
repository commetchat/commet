import 'package:flutter/material.dart';

extension ColorUtils on Color {
  String toHexCode() {
    return "#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
  }

  static Color fromHexCode(String text) {
    final hexCode = text.replaceAll('#', '');
    final hexWithAlpha = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
    try {
      return Color(int.parse(hexWithAlpha, radix: 16));
    } catch (e, _) {
      return Color(0xFFFFFFFF);
    }
  }
}

extension ColorSchemeUtils on ColorScheme {
  Map<String, String> toJson() {
    return {
      "brightness": this.brightness == Brightness.dark ? "dark" : "light",
      "primary": this.primary.toHexCode(),
      "onPrimary": this.onPrimary.toHexCode(),
      "primaryContainer": this.primaryContainer.toHexCode(),
      "onPrimaryContainer": this.onPrimaryContainer.toHexCode(),
      "primaryFixed": this.primaryFixed.toHexCode(),
      "primaryFixedDim": this.primaryFixedDim.toHexCode(),
      "onPrimaryFixed": this.onPrimaryFixed.toHexCode(),
      "onPrimaryFixedVariant": this.onPrimaryFixedVariant.toHexCode(),
      "secondary": this.secondary.toHexCode(),
      "onSecondary": this.onSecondary.toHexCode(),
      "secondaryContainer": this.secondaryContainer.toHexCode(),
      "onSecondaryContainer": this.onSecondaryContainer.toHexCode(),
      "secondaryFixed": this.secondaryFixed.toHexCode(),
      "secondaryFixedDim": this.secondaryFixedDim.toHexCode(),
      "onSecondaryFixed": this.onSecondaryFixed.toHexCode(),
      "onSecondaryFixedVariant": this.onSecondaryFixedVariant.toHexCode(),
      "tertiary": this.tertiary.toHexCode(),
      "onTertiary": this.onTertiary.toHexCode(),
      "tertiaryContainer": this.tertiaryContainer.toHexCode(),
      "onTertiaryContainer": this.onTertiaryContainer.toHexCode(),
      "tertiaryFixed": this.tertiaryFixed.toHexCode(),
      "tertiaryFixedDim": this.tertiaryFixedDim.toHexCode(),
      "onTertiaryFixed": this.onTertiaryFixed.toHexCode(),
      "onTertiaryFixedVariant": this.onTertiaryFixedVariant.toHexCode(),
      "error": this.error.toHexCode(),
      "onError": this.onError.toHexCode(),
      "errorContainer": this.errorContainer.toHexCode(),
      "onErrorContainer": this.onErrorContainer.toHexCode(),
      "surface": this.surface.toHexCode(),
      "onSurface": this.onSurface.toHexCode(),
      "surfaceDim": this.surfaceDim.toHexCode(),
      "surfaceBright": this.surfaceBright.toHexCode(),
      "surfaceContainerLowest": this.surfaceContainerLowest.toHexCode(),
      "surfaceContainerLow": this.surfaceContainerLow.toHexCode(),
      "surfaceContainer": this.surfaceContainer.toHexCode(),
      "surfaceContainerHigh": this.surfaceContainerHigh.toHexCode(),
      "surfaceContainerHighest": this.surfaceContainerHighest.toHexCode(),
      "onSurfaceVariant": this.onSurfaceVariant.toHexCode(),
      "outline": this.outline.toHexCode(),
      "outlineVariant": this.outlineVariant.toHexCode(),
      "shadow": this.shadow.toHexCode(),
      "scrim": this.scrim.toHexCode(),
      "inverseSurface": this.inverseSurface.toHexCode(),
      "onInverseSurface": this.onInverseSurface.toHexCode(),
      "inversePrimary": this.inversePrimary.toHexCode(),
      "surfaceTint": this.surfaceTint.toHexCode(),
    };
  }
}
