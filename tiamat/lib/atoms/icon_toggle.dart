import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'icon_button.dart' as icon;

import 'package:flutter/material.dart' as m;

@WidgetbookUseCase(name: 'Default', type: IconToggle)
Widget wbIconToggle(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
            width: 50,
            height: 50,
            child: Center(
                child: IconToggle(
              icon: Icons.toggle_on,
              state: false,
              size: 20,
            ))),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'On', type: IconToggle)
Widget wbIconToggleOn(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
            width: 50,
            height: 50,
            child: Center(
                child: IconToggle(
              icon: Icons.toggle_on,
              state: true,
              size: 20,
            ))),
      ],
    ),
  );
}

class IconToggle extends StatefulWidget {
  const IconToggle(
      {super.key,
      this.size = 15,
      required this.icon,
      this.onPressed,
      this.state = false,
      this.backgroundColor = m.Colors.transparent});
  final double size;
  final Function(bool newState)? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final bool state;

  @override
  State<IconToggle> createState() => _IconToggleState();
}

class _IconToggleState extends State<IconToggle> {
  @override
  Widget build(BuildContext context) {
    return icon.IconButton(
        icon: widget.icon,
        size: widget.size,
        iconColor: widget.state
            ? m.Theme.of(context).colorScheme.onPrimary
            : m.Theme.of(context).colorScheme.secondary,
        onPressed: () => widget.onPressed?.call(!widget.state),
        backgroundColor: widget.backgroundColor);
  }
}
