import 'package:flutter/material.dart';

extension ColorUtils on Color {
  String toHexCode() {
    return "#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
  }

  static Color fromHexCode(String text) {
    final hexCode = text.replaceAll('#', '');
    final hexWithAlpha = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
    return Color(int.parse(hexWithAlpha, radix: 16));
  }
}
