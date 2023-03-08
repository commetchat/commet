import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/app_config.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({super.key, this.radius = 15, this.icon, this.onPressed});
  final double radius;
  final Function? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        //color: Colors.blue, // Button color
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          splashColor: Theme.of(context).highlightColor, // Splash color
          onTap: () {
            onPressed?.call();
          },
          child: SizedBox(
              width: radius * 2 * AppConfig.uiScale.value,
              height: radius * 2 * AppConfig.uiScale.value,
              child: icon != null ? Icon(icon) : null),
        ),
      ),
    );
  }
}
