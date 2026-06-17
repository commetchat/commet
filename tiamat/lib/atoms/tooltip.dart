import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: "Tooltip", type: Tooltip)
Widget wbTooltip(BuildContext context) {
  return Tile.low1(
    child: const Center(
        child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Tooltip(
              text: "This is a tooltip!",
              child: tiamat.Text.body("Hover me!"),
            ))),
  );
}

class Tooltip extends StatefulWidget {
  const Tooltip(
      {required this.child,
      required this.text,
      this.preferredDirection = AxisDirection.up,
      super.key});
  final Widget child;
  final String text;
  final AxisDirection preferredDirection;

  @override
  State<Tooltip> createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  final controller = JustTheController();

  @override
  Widget build(BuildContext context) {
    return JustTheTooltip(
        content: Theme(
          data: Theme.of(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: tiamat.Text(
              widget.text,
              type: tiamat.TextType.body,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        triggerMode: TooltipTriggerMode.manual,
        preferredDirection: widget.preferredDirection,
        offset: 5,
        tailLength: 5,
        tailBaseWidth: 5,
        controller: controller,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        child:
         MouseRegion(
           onEnter: (event) => controller.showTooltip(),
           onExit: (event) => controller.hideTooltip(),
           child: widget.child,
         )
    );
  }
}
