import 'package:json_annotation/json_annotation.dart';
import 'package:tiamat/config/custom_theme/converters.dart';

part 'custom_glass.g.dart';

@JsonSerializable(converters: [EdgeInsetsConverter()])
class CustomGlass {
  double? opacity;
  double? sigma;

  CustomGlass({
    this.opacity,
    this.sigma,
  });

  factory CustomGlass.fromJson(Map<String, dynamic> json) =>
      _$CustomGlassFromJson(json);

  Map<String, dynamic> toJson() => _$CustomGlassToJson(this);
}
