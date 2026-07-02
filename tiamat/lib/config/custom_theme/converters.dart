import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class ColorConverter implements JsonConverter<Color, String> {
  const ColorConverter();

  @override
  fromJson(json) {
    final hexCode = json.replaceAll('#', '');
    final hexWithAlpha = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
    try {
      return Color(int.parse(hexWithAlpha, radix: 16));
    } catch (e, _) {
      return Color(0xFFFFFFFF);
    }
  }

  @override
  toJson(object) {
    return "#${object.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
  }
}

class LTWHRectConverter implements JsonConverter<Rect, List<dynamic>> {
  const LTWHRectConverter();

  @override
  fromJson(json) {
    return Rect.fromLTWH(json[0], json[1], json[2], json[3]);
  }

  @override
  toJson(object) {
    return [object.left, object.top, object.width, object.height];
  }
}

class EdgeInsetsConverter implements JsonConverter<EdgeInsets, List<dynamic>> {
  const EdgeInsetsConverter();

  @override
  fromJson(json) {
    return EdgeInsets.fromLTRB(json[0], json[1], json[2], json[3]);
  }

  @override
  toJson(object) {
    return [object.left, object.top, object.right, object.bottom];
  }
}
