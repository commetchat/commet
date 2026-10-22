import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:tiamat/config/custom_theme/converters.dart';
import 'package:tiamat/config/custom_theme/custom_borders.dart';
import 'package:tiamat/config/custom_theme/custom_foundation.dart';
import 'package:tiamat/config/custom_theme/custom_glass.dart';
import 'package:tiamat/config/custom_theme/custom_textures.dart';

part 'custom_theme.g.dart';

@JsonSerializable(converters: [ColorConverter()])
class CustomTheme {
  final Map<String, CustomThemeTexture>? textures;
  final Map<String, Color>? colorScheme;
  final Map<String, CustomBorders>? borders;
  final Map<String, CustomGlass>? glass;

  final CustomFoundation? foundation;

  final String base;
  final String? dynamicSchemeVariant;
  final Color? seed;

  const CustomTheme(this.base,
      {this.seed,
      this.dynamicSchemeVariant,
      this.textures,
      this.colorScheme,
      this.foundation,
      this.glass,
      this.borders});

  factory CustomTheme.fromJson(Map<String, dynamic> json) =>
      _$CustomThemeFromJson(json);

  Map<String, dynamic> toJson() => _$CustomThemeToJson(this);

  CustomThemeTexture? getTexture(String name) {
    return textures?[name];
  }

  Color? getColor(String name) {
    return colorScheme?[name];
  }
}
