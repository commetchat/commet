import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../config/app_config.dart';
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
    return ClipOval(
      child: Material(
        color: Theme.of(context).extension<ExtraColors>()!.surfaceLow3,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          splashColor: Theme.of(context).highlightColor, // Splash color
          onTap: () {
            onPressed?.call();
          },
          child: SizedBox(
              width: s(radius * 2),
              height: s(radius * 2),
              child: icon != null
                  ? Align(
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: s(radius),
                      ))
                  : null),
        ),
      ),
    );
  }
}
