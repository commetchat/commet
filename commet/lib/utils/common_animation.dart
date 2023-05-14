import 'package:flutter/widgets.dart';

class CommonAnimations {
  static Animation<double> easeOut(Animation<double> animation) {
    return animation.drive(CurveTween(curve: Curves.easeOutCubic));
  }

  static Animation<double> easeIn(Animation<double> animation) {
    return animation.drive(CurveTween(curve: Curves.easeInCubic));
  }
}
