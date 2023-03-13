import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../config/style/theme_extensions.dart';

@WidgetbookUseCase(name: 'Default', type: CircleButton)
Widget wb_circleButton(BuildContext context) {
  return Center(
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
          shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 10, color: Theme.of(context).colorScheme.shadow)]),
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
