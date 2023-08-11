import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter/material.dart' as material;

@WidgetbookUseCase(name: 'Default', type: IconButton)
Widget wbIconButton(BuildContext context) {
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
              child: IconButton(
            icon: material.Icons.send,
            size: 25,
          )),
        ),
      ],
    ),
  );
}

class IconButton extends StatefulWidget {
  const IconButton(
      {super.key,
      this.size = 15,
      required this.icon,
      this.onPressed,
      this.backgroundColor = material.Colors.transparent,
      this.iconColor});
  final double size;
  final Function? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color? iconColor;

  @override
  State<IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<IconButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return material.ClipOval(
      child: material.Material(
          color: widget.backgroundColor,
          child: material.InkWell(
            onTap: () => widget.onPressed?.call(),
            child: MouseRegion(
              onEnter: (event) {
                setState(() {
                  hovered = true;
                });
              },
              onExit: (event) {
                setState(() {
                  hovered = false;
                });
              },
              cursor: material.MaterialStateMouseCursor.clickable,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: widget.size,
                      color: widget.iconColor ??
                          (hovered
                              ? material.Theme.of(context).colorScheme.onPrimary
                              : null),
                    )),
              ),
            ),
          )),
    );
  }
}
