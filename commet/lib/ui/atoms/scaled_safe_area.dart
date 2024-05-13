import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScaledSafeArea extends SafeArea {
  const ScaledSafeArea({
    super.key,
    required super.child,
    bool bottom = true,
    bool top = true,
    bool left = true,
    bool right = true,
  }) : super(
          bottom: bottom,
          top: top,
          right: right,
          left: left,
        );

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    EdgeInsets padding = MediaQuery.of(context).scale().viewPadding;
    if (maintainBottomViewPadding) {
      padding = padding.copyWith(
          bottom: MediaQuery.of(context).scale().viewPadding.bottom);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }
}
