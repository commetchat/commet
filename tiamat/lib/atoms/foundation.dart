import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class Foundation extends StatelessWidget {
  const Foundation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var data = Theme.of(context).extension<FoundationSettings>();

    bool alignImage =
        [BoxFit.cover, BoxFit.fill].contains(data?.imageFit) == false;
    return Container(
      color: data?.color,
      child: Stack(
        fit: data?.stackFit ?? StackFit.expand,
        children: [
          if (data?.image != null)
            if (!alignImage)
              Image(
                image: data!.image!,
                fit: data.imageFit,
              ),
          if (data?.image != null)
            if (alignImage)
              Align(
                alignment: data?.imageAlignment ?? Alignment.center,
                child: Image(
                  image: data!.image!,
                  fit: data.imageFit,
                ),
              ),
          child,
        ],
      ),
    );
  }
}
