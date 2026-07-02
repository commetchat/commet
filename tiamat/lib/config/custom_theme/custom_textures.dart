import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tiamat/config/custom_theme/converters.dart';

part 'custom_textures.g.dart';

@JsonSerializable(converters: [LTWHRectConverter()])
class CustomThemeTexture {
  String file;

  Rect? centerSlice;

  double? scale;

  CustomThemeTexture(this.file, {this.centerSlice});

  factory CustomThemeTexture.fromJson(Map<String, dynamic> json) =>
      _$CustomThemeTextureFromJson(json);

  Map<String, dynamic> toJson() => _$CustomThemeTextureToJson(this);
}
