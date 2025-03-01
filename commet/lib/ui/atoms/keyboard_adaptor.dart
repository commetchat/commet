import 'dart:math';

import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';

class KeyboardAdaptor extends StatelessWidget {
  const KeyboardAdaptor(Widget this.child, {super.key, this.ignore = false});
  final Widget? child;
  final bool ignore;

  @override
  Widget build(BuildContext context) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    return ScaledSafeArea(
        bottom: false,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, offset), child: child));
  }
}
