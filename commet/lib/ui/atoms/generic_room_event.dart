import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';

class GenericRoomEvent extends StatelessWidget {
  const GenericRoomEvent(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: EdgeInsets.all(2.0 * AppConfig.uiScale.value),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20 * AppConfig.uiScale.value, 8 * AppConfig.uiScale.value,
                  20 * AppConfig.uiScale.value, 8 * AppConfig.uiScale.value),
              child: Row(
                children: [
                  Avatar.medium(image: null, isPadding: true),
                  Icon(icon),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10 * AppConfig.uiScale.value, 0, 0, 0),
                    child: Flexible(child: Text(text)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
