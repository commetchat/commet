import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground(
      {required this.begin,
      required this.end,
      super.key,
      this.child,
      required this.backgroundColor});
  final Color backgroundColor;
  final Widget? child;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.transparent, backgroundColor],
              begin: begin,
              stops: const [0, 1],
              end: end)),
      child: child,
    );
  }
}
