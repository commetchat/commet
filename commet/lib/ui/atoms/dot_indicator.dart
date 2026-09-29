import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget {
  const DotIndicator({this.color, super.key});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
