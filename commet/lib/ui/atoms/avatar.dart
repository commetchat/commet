import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.image,
    required this.radius,
  }) : super(key: key);

  const Avatar.small({
    Key? key,
    this.image,
  })  : radius = 15,
        super(key: key);

  const Avatar.medium({
    Key? key,
    required this.image,
  })  : radius = 22,
        super(key: key);

  const Avatar.large({
    Key? key,
    this.image,
  })  : radius = 44,
        super(key: key);

  final double radius;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius * 0.8), image: DecorationImage(image: image!))),
      );
    }
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius * 0.8))),
    );
  }
}
