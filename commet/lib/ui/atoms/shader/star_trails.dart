import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class StarTrailsBackground extends StatefulWidget {
  const StarTrailsBackground({super.key, this.child});
  final Widget? child;

  @override
  State<StarTrailsBackground> createState() => _StarTrailsBackgroundState();
}

class _StarTrailsBackgroundState extends State<StarTrailsBackground> {
  static bool loadingShader = false;
  static FragmentShader? shader;
  late Timer timer;
  double delta = 0;

  void loadShader() async {
    loadingShader = true;

    var program =
        await FragmentProgram.fromAsset('assets/shader/star_trails.frag');
    shader = program.fragmentShader();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      setState(() {
        loadingShader = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (shader == null && loadingShader == false) {
      loadShader();
    }

    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        delta += 1 / 60;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (shader == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return CustomPaint(
        painter: StarTrailsPainter(shader!, delta * .3),
        child: Container(
          child: widget.child,
        ),
      );
    }
  }
}

class StarTrailsPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;

  const StarTrailsPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time * 0.5);

    paint.shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
