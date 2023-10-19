import 'package:flutter/material.dart';

class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.surfaceHigh1,
    required this.surfaceLow1,
    required this.surfaceLow2,
    required this.surfaceLow3,
    required this.surfaceLow4,
    required this.highlight,
    required this.codeHighlight,
    required this.outline,
  });

  final Color surfaceHigh1;
  final Color surfaceLow1;
  final Color surfaceLow2;
  final Color surfaceLow3;
  final Color surfaceLow4;
  final Color highlight;
  final Color codeHighlight;
  final Color outline;

  @override
  ThemeExtension<ExtraColors> copyWith(
          {Color? surfaceHigh1,
          Color? surfaceLow,
          Color? surfaceLow2,
          Color? surfaceLow3,
          Color? surfaceLow4,
          Color? highlight,
          Color? outline,
          Color? codeHighlight}) =>
      ExtraColors(
        surfaceHigh1: surfaceHigh1 ?? this.surfaceHigh1,
        surfaceLow1: surfaceLow ?? surfaceLow1,
        surfaceLow2: surfaceLow2 ?? this.surfaceLow2,
        surfaceLow3: surfaceLow3 ?? this.surfaceLow3,
        surfaceLow4: surfaceLow4 ?? this.surfaceLow4,
        highlight: highlight ?? this.highlight,
        outline: outline ?? this.outline,
        codeHighlight: codeHighlight ?? this.codeHighlight,
      );

  @override
  ThemeExtension<ExtraColors> lerp(
      covariant ThemeExtension<ExtraColors>? other, double t) {
    if (other is! ExtraColors) return this;

    return ExtraColors(
        surfaceHigh1: Color.lerp(surfaceHigh1, other.surfaceHigh1, t)!,
        surfaceLow1: Color.lerp(surfaceLow1, other.surfaceLow1, t)!,
        surfaceLow2: Color.lerp(surfaceLow2, other.surfaceLow2, t)!,
        surfaceLow3: Color.lerp(surfaceLow3, other.surfaceLow3, t)!,
        surfaceLow4: Color.lerp(surfaceLow4, other.surfaceLow4, t)!,
        highlight: Color.lerp(highlight, other.highlight, t)!,
        outline: Color.lerp(outline, other.outline, t)!,
        codeHighlight: Color.lerp(codeHighlight, other.codeHighlight, t)!);
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
  ThemeExtension<ThemeSettings> lerp(
      covariant ThemeExtension<ThemeSettings>? other, double t) {
    if (other is! ExtraColors) return this;

    return ThemeSettings(frosted: frosted);
  }
}
