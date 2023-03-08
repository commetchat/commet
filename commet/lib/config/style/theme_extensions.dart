import 'package:flutter/material.dart';

class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.surfaceHigh1,
    required this.surfaceLow1,
    required this.surfaceLow2,
    required this.surfaceLow3,
    required this.surfaceLowest,
    required this.highlight,
  });

  final Color surfaceHigh1;
  final Color surfaceLow1;
  final Color surfaceLow2;
  final Color surfaceLow3;
  final Color surfaceLowest;
  final Color highlight;

  @override
  ThemeExtension<ExtraColors> copyWith(
          {Color? surfaceHigh1, Color? surfaceLow, Color? surfaceLow2, Color? surfaceLow3, Color? surfaceLowest}) =>
      ExtraColors(
        surfaceHigh1: surfaceHigh1 ?? this.surfaceHigh1,
        surfaceLow1: surfaceLow ?? this.surfaceLow1,
        surfaceLow2: surfaceLow2 ?? this.surfaceLow2,
        surfaceLow3: surfaceLow3 ?? this.surfaceLow3,
        surfaceLowest: surfaceLowest ?? this.surfaceLowest,
        highlight: highlight ?? this.highlight,
      );

  @override
  ThemeExtension<ExtraColors> lerp(covariant ThemeExtension<ExtraColors>? other, double t) {
    if (other is! ExtraColors) return this;

    return ExtraColors(
      surfaceHigh1: Color.lerp(surfaceHigh1, other.surfaceHigh1, t)!,
      surfaceLow1: Color.lerp(surfaceLow1, other.surfaceLow1, t)!,
      surfaceLow2: Color.lerp(surfaceLow2, other.surfaceLow2, t)!,
      surfaceLow3: Color.lerp(surfaceLow3, other.surfaceLow3, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

class ThemeSettings extends ThemeExtension<ThemeSettings> {
  const ThemeSettings({required this.frosted});

  final bool frosted;

  @override
  ThemeExtension<ThemeSettings> copyWith({bool? frosted}) {
    return ThemeSettings(frosted: frosted ?? this.frosted);
  }

  @override
  ThemeExtension<ThemeSettings> lerp(covariant ThemeExtension<ThemeSettings>? other, double t) {
    if (other is! ExtraColors) return this;

    return ThemeSettings(frosted: frosted);
  }
}
