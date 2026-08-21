import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiamat/config/custom_theme/custom_borders.dart';
import 'package:tiamat/config/custom_theme/custom_foundation.dart';
import 'package:tiamat/config/custom_theme/custom_glass.dart';
import 'package:tiamat/config/custom_theme/custom_textures.dart';
import 'package:path/path.dart' as path;

class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.codeHighlight,
    required this.linkColor,
  });

  final Color codeHighlight;
  final Color linkColor;

  static ExtraColors fromScheme(ColorScheme scheme) {
    var sat = scheme.brightness == Brightness.dark ? 0.7 : 1.0;

    return ExtraColors(
      codeHighlight:
          HSVColor.fromColor(scheme.tertiary).withSaturation(sat).toColor(),
      linkColor:
          HSVColor.fromColor(scheme.primary).withSaturation(sat).toColor(),
    );
  }

  @override
  ThemeExtension<ExtraColors> copyWith(
          {Color? linkColor, Color? outline, Color? codeHighlight}) =>
      ExtraColors(
          codeHighlight: codeHighlight ?? this.codeHighlight,
          linkColor: linkColor ?? this.linkColor);

  @override
  ThemeExtension<ExtraColors> lerp(
      covariant ThemeExtension<ExtraColors>? other, double t) {
    if (other is! ExtraColors) return this;

    return ExtraColors(
        codeHighlight: Color.lerp(codeHighlight, other.codeHighlight, t)!,
        linkColor: Color.lerp(linkColor, other.linkColor, t)!);
  }
}

class ThemeSettings extends ThemeExtension<ThemeSettings> {
  const ThemeSettings(
      {this.caulkPadding = 2,
      this.caulkBorderRadius = 0,
      this.shadowBlurRadius = 0,
      this.caulkStrokeThickness = 1,
      this.caulkBorders = false});

  final bool caulkBorders;

  final double caulkPadding;
  final double caulkBorderRadius;

  final double shadowBlurRadius;
  final double caulkStrokeThickness;

  @override
  ThemeExtension<ThemeSettings> copyWith({bool? glass}) {
    return ThemeSettings();
  }

  @override
  ThemeExtension<ThemeSettings> lerp(
      covariant ThemeExtension<ThemeSettings>? other, double t) {
    if (other is! ThemeSettings) return this;

    return ThemeSettings(
        caulkPadding: lerpDouble(caulkPadding, other.caulkPadding, t)!,
        caulkBorders: other.caulkBorders,
        caulkBorderRadius:
            lerpDouble(caulkBorderRadius, other.caulkBorderRadius, t)!,
        shadowBlurRadius:
            lerpDouble(shadowBlurRadius, other.shadowBlurRadius, t)!,
        caulkStrokeThickness:
            lerpDouble(caulkStrokeThickness, other.caulkStrokeThickness, t)!);
  }
}

class GlassSettings extends ThemeExtension<GlassSettings> {
  final Map<String, CustomGlass>? glass;

  const GlassSettings({this.glass});

  @override
  ThemeExtension<GlassSettings> copyWith() {
    return GlassSettings();
  }

  CustomGlass? getGlass(String key) {
    return glass?[key];
  }

  @override
  ThemeExtension<GlassSettings> lerp(
      covariant ThemeExtension<GlassSettings>? other, double t) {
    if (other is! GlassSettings) return this;

    return other;
  }
}

class FoundationSettings extends ThemeExtension<FoundationSettings> {
  final CustomFoundation settings;
  final String? rootDirectory;

  const FoundationSettings({
    this.rootDirectory,
    required this.settings,
  });

  @override
  ThemeExtension<FoundationSettings> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<FoundationSettings> lerp(
      covariant ThemeExtension<FoundationSettings>? other, double t) {
    if (other is! FoundationSettings) return this;

    if (t > 0.5) {
      return FoundationSettings(
          rootDirectory: rootDirectory, settings: settings);
    } else {
      return other;
    }
  }

  NinePatchTexture? getTexture() {
    if (settings.image == null) return null;
    if (rootDirectory == null) return null;

    var imagePath = path.join(rootDirectory!, settings.image!.file);

    return NinePatchTexture(
        settings.image!.centerSlice,
        FileImage(File(imagePath), scale: settings.image!.scale ?? 1.0),
        settings.image!.scale);
  }
}

class ShadowSettings extends ThemeExtension<ShadowSettings> {
  List<BoxShadow> shadows;

  ShadowSettings(this.shadows);

  @override
  ThemeExtension<ShadowSettings> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<ShadowSettings> lerp(
      covariant ThemeExtension<ShadowSettings>? other, double t) {
    if (other is! ShadowSettings) return this;
    return other;
  }
}

class NinePatchTexture {
  Rect? offset;
  ImageProvider image;
  double? scale;

  NinePatchTexture(this.offset, this.image, this.scale);
}

class PanelTextures extends ThemeExtension<PanelTextures> {
  Map<String, CustomThemeTexture> images;
  final String rootDirectory;

  PanelTextures(this.images, this.rootDirectory);

  @override
  ThemeExtension<PanelTextures> copyWith() {
    throw UnimplementedError();
  }

  NinePatchTexture? getTexture(String key) {
    var image = images[key];
    if (image == null) return null;

    var imagePath = path.join(rootDirectory, image.file);

    return NinePatchTexture(image.centerSlice,
        FileImage(File(imagePath), scale: image.scale ?? 1.0), image.scale);
  }

  @override
  ThemeExtension<PanelTextures> lerp(
      covariant ThemeExtension<PanelTextures>? other, double t) {
    if (other is! PanelTextures) return this;
    return other;
  }
}

class CustomThemeBorders extends ThemeExtension<CustomThemeBorders> {
  Map<String, CustomBorders> borders;

  CustomThemeBorders(this.borders);

  @override
  ThemeExtension<CustomThemeBorders> copyWith() {
    throw UnimplementedError();
  }

  CustomBorders? getBorder(String key) {
    return borders[key];
  }

  @override
  ThemeExtension<CustomThemeBorders> lerp(
      covariant ThemeExtension<CustomThemeBorders>? other, double t) {
    if (other is! CustomThemeBorders) return this;
    return other;
  }
}
