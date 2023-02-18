import 'package:flutter/material.dart';

class ExtraColors extends ThemeExtension<ExtraColors> {
  const ExtraColors({
    required this.surfaceLow,
    required this.surfaceExtraLow,
    required this.surfaceLowest,
  });

  final Color surfaceLow;
  final Color surfaceExtraLow;
  final Color surfaceLowest;

  @override
  ThemeExtension<ExtraColors> copyWith({Color? surfaceLow, Color? surfaceExtraLow, Color? surfaceLowest}) => ExtraColors(surfaceLow: surfaceLow ?? this.surfaceLow, surfaceExtraLow: surfaceExtraLow ?? this.surfaceExtraLow, surfaceLowest: surfaceLowest ?? this.surfaceLowest);

  @override
  ThemeExtension<ExtraColors> lerp(covariant ThemeExtension<ExtraColors>? other, double t) {
    if (other is! ExtraColors) return this;

    return ExtraColors(
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceExtraLow: Color.lerp(surfaceExtraLow, other.surfaceExtraLow, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
    );
  }
}
