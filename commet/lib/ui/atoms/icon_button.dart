import 'package:flutter/material.dart';

class IconButton extends StatefulWidget {
  const IconButton(
      {super.key, this.size = 15, required this.icon, this.onPressed});
  final double size;
  final Function? onPressed;
  final IconData icon;

  @override
  State<IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<IconButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: GestureDetector(
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
            cursor: WidgetStateMouseCursor.clickable,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: widget.size,
                      color: hovered
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    )),
              ),
            ),
          ),
        ));
  }
}
