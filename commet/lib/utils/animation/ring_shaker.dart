import 'dart:math';

import 'package:flutter/material.dart';

class RingShakerAnimation extends StatefulWidget {
  const RingShakerAnimation({required this.child, super.key});
  final Widget child;
  @override
  State<RingShakerAnimation> createState() => _RingShakerAnimationState();
}

class _RingShakerAnimationState extends State<RingShakerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(vsync: this);
    controller.repeat(min: 0, max: 1, period: const Duration(seconds: 2));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var amp = sin(controller.value * 50);
        amp = amp * pow(1 - controller.value, 2);
        amp *= 0.15;
        return Transform.rotate(
          angle: amp,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
