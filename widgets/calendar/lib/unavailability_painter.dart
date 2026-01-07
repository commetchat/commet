import 'dart:math';

import 'package:flutter/material.dart';

class UnavailabilityPainter extends CustomPainter {
  UnavailabilityPainter({required this.color, this.vertical = true});

  final Color color;

  final vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint fillStroke = Paint()
      ..color = color.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (vertical) {
      var offset = tan(0.1) * size.width;
      for (double i = -offset; i < size.height; i += 10) {
        canvas.drawLine(
            Offset(0, i + offset), Offset(size.width, i), fillStroke);
      }
    } else {
      var offset = tan(0.4) * size.height;
      for (double i = -offset; i < size.width; i += 10) {
        canvas.drawLine(
            Offset(i + offset, 0), Offset(i, size.height), fillStroke);
      }
    }

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = 4;

    final Path path = Path()
      ..addRRect(
          RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(8)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UnavailabilityPainter oldPainter) {
    return oldPainter.color != color;
  }
}
