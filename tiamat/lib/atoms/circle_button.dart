import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../config/style/theme_extensions.dart';

@UseCase(name: 'Default', type: CircleButton)
Widget wbcircleButton(BuildContext context) {
  return const Center(
      child: CircleButton(
    radius: 25,
    icon: Icons.add,
  ));
}

class CircleButton extends StatelessWidget {
  const CircleButton({super.key, this.radius = 15, this.icon, this.onPressed});
  final double radius;
  final Function? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Theme.of(context).extension<ExtraColors>()!.outline,
            width: 1.2),
      ),
      child: ClipOval(
        child: Material(
          color: Theme.of(context).extension<ExtraColors>()!.surfaceLow3,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            splashColor: Theme.of(context).highlightColor, // Splash color
            onTap: () {
              onPressed?.call();
            },
            child: SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: icon != null
                    ? Align(
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: radius,
                        ))
                    : null),
          ),
        ),
      ),
    );
  }
}
