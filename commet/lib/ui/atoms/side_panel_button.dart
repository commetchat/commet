import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import '../../config/style/theme_extensions.dart';

class SidePanelButton extends StatefulWidget {
  SidePanelButton({super.key, this.width = 44, this.onTap, this.tooltip, this.image});
  double width;
  void Function()? onTap;
  String? tooltip;
  ImageProvider? image;

  @override
  State<SidePanelButton> createState() => _SidePanelButtonState();
}

class _SidePanelButtonState extends State<SidePanelButton> {
  BorderRadiusGeometry _borderRadius = BorderRadius.circular(20);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GestureDetector(
              onTap: () => {widget.onTap?.call()},
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (event) {
                    setState(() {
                      _borderRadius = BorderRadius.circular(8);
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      _borderRadius = BorderRadius.circular(20);
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
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.tooltip!),
                          ),
                          child: createImageContainer(),
                        )
                      : createImageContainer()),
            ),
          ),
        ),
      ),
    );
  }

  AnimatedContainer createImageContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
          borderRadius: _borderRadius,
          image: widget.image != null
              ? DecorationImage(image: widget.image!, fit: BoxFit.fitHeight)
              : const DecorationImage(
                  image: AssetImage("assets/images/placeholder/generic/checker_red.png"), fit: BoxFit.fitHeight)),
    );
  }
}
