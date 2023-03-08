import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/app_config.dart';

class Avatar extends StatelessWidget {
  const Avatar({Key? key, this.image, required this.radius, this.placeholderText = null, this.isPadding = false})
      : super(key: key);

  const Avatar.small({
    Key? key,
    this.image,
    this.placeholderText = null,
    this.isPadding = false,
  })  : radius = 15,
        super(key: key);

  const Avatar.medium({Key? key, required this.image, this.placeholderText = null, this.isPadding = false})
      : radius = 22,
        super(key: key);

  const Avatar.large({Key? key, this.image, this.placeholderText = null, this.isPadding = false})
      : radius = 44,
        super(key: key);

  final double radius;
  final ImageProvider? image;
  final String? placeholderText;
  final bool isPadding;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return SizedBox(
        width: s(radius * 2),
        height: s(radius * 2),
        child: DecoratedBox(
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(s(radius)), image: DecorationImage(image: image!))),
      );
    }
    return SizedBox(
      width: s(radius * 2),
      height: isPadding ? null : s(radius * 2),
      child: placeholderText != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(s(radius)),
                color: Colors.green,
              ),
              child: Align(
                  alignment: Alignment.center,
                  child: placeholderText != null
                      ? Text(
                          placeholderText!.substring(0, 1).toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: radius),
                        )
                      : null),
            )
          : null,
    );
  }
}
