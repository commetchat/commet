import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class Tooltip extends StatelessWidget {
  const Tooltip(
      {required this.child,
      required this.text,
      this.preferredDirection = AxisDirection.up,
      super.key});
  final Widget child;
  final String text;
  final AxisDirection preferredDirection;

  @override
  Widget build(BuildContext context) {
    return JustTheTooltip(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text(text),
        ),
        preferredDirection: preferredDirection,
        offset: 5,
        tailLength: 5,
        tailBaseWidth: 5,
        backgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow4,
        child: child);
  }
}
