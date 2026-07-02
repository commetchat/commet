import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tiamat/config/custom_theme/converters.dart';
import 'package:tiamat/config/custom_theme/custom_textures.dart';

part 'custom_foundation.g.dart';

@JsonSerializable(converters: [ColorConverter(), EdgeInsetsConverter()])
class CustomFoundation {
  Color? color;

  CustomThemeTexture? image;

  EdgeInsets? padding;

  CustomFoundation({this.color, this.image, this.padding});

  factory CustomFoundation.fromJson(Map<String, dynamic> json) =>
      _$CustomFoundationFromJson(json);

  Map<String, dynamic> toJson() => _$CustomFoundationToJson(this);
}
