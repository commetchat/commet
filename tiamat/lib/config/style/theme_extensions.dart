import 'dart:ui';

import 'package:flutter/material.dart';

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
      {this.caulkPadding = 0,
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
  const GlassSettings(
      {this.surfaceSigma = 10,
      this.surfaceOpacity = 0.5,
      this.surfaceDimSigma = 20,
      this.surfaceDimOpacity = 0.6,
      this.surfaceContainerLowestSigma = 30,
      this.surfaceContainerLowestOpacity = 0.7,
      this.surfaceContainerLowSigma = 25,
      this.surfaceContainerLowOpacity = 0.6,
      this.surfaceContainerSigma = 5,
      this.surfaceContainerOpacity = 0.3,
      this.surfaceContainerHighSigma = 10,
      this.surfaceContainerHighOpacity = 0.7,
      this.surfaceContainerHighestSigma = 10,
      this.surfaceContainerHighestOpacity = 0.6});

  final double surfaceSigma;
  final double surfaceOpacity;

  final double surfaceDimSigma;
  final double surfaceDimOpacity;

  final double surfaceContainerLowestSigma;
  final double surfaceContainerLowestOpacity;

  final double surfaceContainerLowSigma;
  final double surfaceContainerLowOpacity;

  final double surfaceContainerSigma;
  final double surfaceContainerOpacity;

  final double surfaceContainerHighSigma;
  final double surfaceContainerHighOpacity;

  final double surfaceContainerHighestSigma;
  final double surfaceContainerHighestOpacity;

  @override
  ThemeExtension<GlassSettings> copyWith({
    double? surfaceSigma,
    double? surfaceOpacity,
    double? surfaceDimSigma,
    double? surfaceDimOpacity,
    double? surfaceContainerLowestSigma,
    double? surfaceContainerLowestOpacity,
    double? surfaceContainerLowSigma,
    double? surfaceContainerLowOpacity,
    double? surfaceContainerSigma,
    double? surfaceContainerOpacity,
    double? surfaceContainerHighSigma,
    double? surfaceContainerHighOpacity,
    double? surfaceContainerHighestSigma,
    double? surfaceContainerHighestOpacity,
  }) {
    return GlassSettings(
      surfaceSigma: surfaceSigma ?? this.surfaceSigma,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      surfaceDimSigma: surfaceDimSigma ?? this.surfaceDimSigma,
      surfaceDimOpacity: surfaceDimOpacity ?? this.surfaceDimOpacity,
      surfaceContainerLowestSigma:
          surfaceContainerLowestSigma ?? this.surfaceContainerLowestSigma,
      surfaceContainerLowestOpacity:
          surfaceContainerLowestOpacity ?? this.surfaceContainerLowestOpacity,
      surfaceContainerLowSigma:
          surfaceContainerLowSigma ?? this.surfaceContainerLowSigma,
      surfaceContainerLowOpacity:
          surfaceContainerLowOpacity ?? this.surfaceContainerLowOpacity,
      surfaceContainerSigma:
          surfaceContainerSigma ?? this.surfaceContainerSigma,
      surfaceContainerOpacity:
          surfaceContainerOpacity ?? this.surfaceContainerOpacity,
      surfaceContainerHighSigma:
          surfaceContainerHighSigma ?? this.surfaceContainerHighSigma,
      surfaceContainerHighOpacity:
          surfaceContainerHighOpacity ?? this.surfaceContainerHighOpacity,
      surfaceContainerHighestSigma:
          surfaceContainerHighestSigma ?? this.surfaceContainerHighestSigma,
      surfaceContainerHighestOpacity:
          surfaceContainerHighestOpacity ?? this.surfaceContainerHighestOpacity,
    );
  }

  @override
  ThemeExtension<GlassSettings> lerp(
      covariant ThemeExtension<GlassSettings>? other, double t) {
    if (other is! GlassSettings) return this;

    return GlassSettings(
      surfaceSigma: lerpDouble(surfaceSigma, other.surfaceSigma, t)!,
      surfaceOpacity: lerpDouble(surfaceOpacity, other.surfaceOpacity, t)!,
      surfaceDimSigma: lerpDouble(surfaceDimSigma, other.surfaceDimSigma, t)!,
      surfaceDimOpacity:
          lerpDouble(surfaceDimOpacity, other.surfaceDimOpacity, t)!,
      surfaceContainerLowestSigma: lerpDouble(
          surfaceContainerLowestSigma, other.surfaceContainerLowestSigma, t)!,
      surfaceContainerLowestOpacity: lerpDouble(surfaceContainerLowestOpacity,
          other.surfaceContainerLowestOpacity, t)!,
      surfaceContainerLowSigma: lerpDouble(
          surfaceContainerLowSigma, other.surfaceContainerLowSigma, t)!,
      surfaceContainerLowOpacity: lerpDouble(
          surfaceContainerLowOpacity, other.surfaceContainerLowOpacity, t)!,
      surfaceContainerSigma:
          lerpDouble(surfaceContainerSigma, other.surfaceContainerSigma, t)!,
      surfaceContainerOpacity: lerpDouble(
          surfaceContainerOpacity, other.surfaceContainerOpacity, t)!,
      surfaceContainerHighSigma: lerpDouble(
          surfaceContainerHighSigma, other.surfaceContainerHighSigma, t)!,
      surfaceContainerHighOpacity: lerpDouble(
          surfaceContainerHighOpacity, other.surfaceContainerHighOpacity, t)!,
      surfaceContainerHighestSigma: lerpDouble(
          surfaceContainerHighestSigma, other.surfaceContainerHighestSigma, t)!,
      surfaceContainerHighestOpacity: lerpDouble(surfaceContainerHighestOpacity,
          other.surfaceContainerHighestOpacity, t)!,
    );
  }
}

class FoundationSettings extends ThemeExtension<FoundationSettings> {
  const FoundationSettings({
    this.color,
    this.imageFit = BoxFit.cover,
    this.stackFit = StackFit.expand,
    this.imageAlignment = Alignment.center,
    this.image,
  });

  final ImageProvider? image;
  final BoxFit imageFit;
  final StackFit stackFit;
  final Alignment imageAlignment;
  final Color? color;

  @override
  ThemeExtension<FoundationSettings> copyWith(
      {ImageProvider? image,
      BoxFit? imageFit,
      Color? color,
      StackFit? stackFit,
      Alignment? imageAlignment}) {
    return FoundationSettings(
        color: color ?? this.color,
        image: image ?? this.image,
        imageFit: imageFit ?? this.imageFit,
        stackFit: stackFit ?? this.stackFit,
        imageAlignment: imageAlignment ?? this.imageAlignment);
  }

  @override
  ThemeExtension<FoundationSettings> lerp(
      covariant ThemeExtension<FoundationSettings>? other, double t) {
    if (other is! FoundationSettings) return this;

    return FoundationSettings(
        image: t > 0.5 ? other.image : image,
        imageFit: t > 0.5 ? other.imageFit : imageFit,
        stackFit: t > 0.5 ? other.stackFit : stackFit,
        imageAlignment: t > 0.5 ? other.imageAlignment : imageAlignment,
        color: Color.lerp(color, other.color, t)!);
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
