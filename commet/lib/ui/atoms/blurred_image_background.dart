import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class BlurredImageBackground extends StatelessWidget {
  const BlurredImageBackground(this.image,
      {super.key, this.child, this.sigma = 5, this.height = 90, this.backgroundColor = Colors.transparent});
  final ImageProvider image;
  final Color backgroundColor;
  final Widget? child;
  final double height;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
            child: DecoratedBox(
              decoration: BoxDecoration(image: DecorationImage(image: image, fit: BoxFit.cover)),
              child: Container(),
            ),
          ),
        ),
        ClipRect(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.transparent, backgroundColor],
                        begin: Alignment.topCenter,
                        stops: [0, 0.8],
                        end: Alignment.bottomCenter)),
                child: Container())),
        SafeArea(child: SizedBox(height: height, child: child != null ? child! : Container()))
      ],
    );
  }
}
