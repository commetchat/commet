import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tiamat/config/custom_theme/converters.dart';

part 'custom_borders.g.dart';

@JsonSerializable(converters: [EdgeInsetsConverter()])
class CustomBorders {
  EdgeInsets? innerPadding;
  EdgeInsets? outerPadding;
  double? borderRadius;

  CustomBorders({
    this.innerPadding,
    this.outerPadding,
    this.borderRadius,
  });

  factory CustomBorders.fromJson(Map<String, dynamic> json) =>
      _$CustomBordersFromJson(json);

  Map<String, dynamic> toJson() => _$CustomBordersToJson(this);
}
