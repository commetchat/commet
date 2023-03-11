import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';

import './text.dart' as t;

class SimpleTextButton extends StatelessWidget {
  const SimpleTextButton(this.text, {super.key, this.icon, this.onTap, this.highlighted = false});
  final String text;

  final IconData? icon;
  final bool highlighted;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        clipBehavior: Clip.antiAlias,
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(highlighted ? Theme.of(context).highlightColor : null),
        ),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.all(s(1.0)),
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    size: s(20),
                    icon!,
                    weight: 0.5,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(8), 0, 0, 0),
              child: Align(alignment: Alignment.centerLeft, child: t.Text.ui(text, context)),
            ),
          ],
        ),
        onPressed: () => onTap?.call());
  }
}
