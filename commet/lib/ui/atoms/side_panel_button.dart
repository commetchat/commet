import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import './text.dart' as t;

import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';

class SidePanelButton extends StatefulWidget {
  SidePanelButton({super.key, this.width = 44, this.onTap, this.tooltip, this.image, this.icon});
  double width;
  void Function()? onTap;
  String? tooltip;
  ImageProvider? image;
  IconData? icon;

  @override
  State<SidePanelButton> createState() => _SidePanelButtonState();
}

class _SidePanelButtonState extends State<SidePanelButton> {
  double _borderRadius = 20;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.all(s(3)),
          child: GestureDetector(
            onTap: () => {widget.onTap?.call()},
            child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (event) {
                  setState(() {
                    _borderRadius = 8;
                  });
                },
                onExit: (event) {
                  setState(() {
                    _borderRadius = 20;
                  });
                },
                child: widget.tooltip != null
                    ? JustTheTooltip(
                        preferredDirection: AxisDirection.right,
                        offset: 40,
                        tailLength: 5,
                        tailBaseWidth: 5,
                        //shadow: BoxShadow(blurRadius: 4, color: Colors.black, spreadRadius: 1),
                        backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLowest,
                        content: Padding(
                          padding: EdgeInsets.all(s(8.0)),
                          child: t.Text.ui(widget.tooltip!, context),
                        ),
                        child: createImageContainer(context),
                      )
                    : createImageContainer(context)),
          ),
        ),
      ),
    );
  }

  AnimatedContainer createImageContainer(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
          color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
          borderRadius: BorderRadius.circular(s(_borderRadius)),
          image: widget.image != null ? DecorationImage(image: widget.image!, fit: BoxFit.fitHeight) : null),
      child: widget.icon != null
          ? Align(
              alignment: Alignment.center,
              child: Icon(
                widget.icon!,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : null,
    );
  }
}
