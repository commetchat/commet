import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiamat/atoms/shader_background.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@WidgetbookUseCase(name: 'Default', type: GlassTile)
Widget wbtileGlass(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
              width: 200, height: 200, child: GlassTile(child: Center(child: tiamat.Text.body("Hello, World!")))),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
              width: 200, height: 200, child: GlassTile(child: Center(child: tiamat.Text.body("Hello, World!")))),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
              width: 200, height: 200, child: GlassTile(child: Center(child: tiamat.Text.body("Hello, World!")))),
        ),
      ],
    ),
  );
}

class GlassTile extends StatelessWidget {
  const GlassTile({Key? key, this.child, this.opacity = 0.2, this.sigma = 1, this.color = Colors.transparent})
      : super(key: key);
  final double sigma;
  final double opacity;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRect(
            child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: const ShaderBackground())),
        Container(color: color.withAlpha((opacity * 255.0).toInt()), child: child!),
      ],
    );
  }
}
