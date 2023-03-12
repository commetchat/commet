import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class TextureCoordinatePainter extends CustomPainter {
  final FragmentShader shader;
  final Rect offset;
  final double windowWidth;
  final double windowHeight;
  final ui.Image image;

  TextureCoordinatePainter(FragmentShader fragmentShader, this.image, this.windowWidth, this.windowHeight, this.offset)
      : shader = fragmentShader;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    shader.setImageSampler(0, image!);
    shader.setFloat(0, offset.top);
    shader.setFloat(1, offset.left);
    shader.setFloat(2, offset.right);
    shader.setFloat(3, offset.bottom);

    shader.setFloat(4, windowWidth);
    shader.setFloat(5, windowHeight);

    paint.shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
