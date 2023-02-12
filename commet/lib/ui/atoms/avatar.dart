import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    required this.image,
    required this.radius,
  }) : super(key: key);

  const Avatar.small({
    Key? key,
    required this.image,
  })  : radius = 15,
        super(key: key);

  const Avatar.medium({
    Key? key,
    required this.image,
  })  : radius = 22,
        super(key: key);

  const Avatar.large({
    Key? key,
    required this.image,
  })  : radius = 44,
        super(key: key);

  final double radius;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: CircleAvatar(
        radius: radius,
        foregroundImage: image,
      ),
    );
  }
}
