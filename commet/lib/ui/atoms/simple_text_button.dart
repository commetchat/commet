import 'package:flutter/material.dart';

import '../../config/style/theme_extensions.dart';

class SimpleTextButton extends StatelessWidget {
  const SimpleTextButton(this.text, {super.key, this.icon, this.onTap, this.highlighted = false});
  final String text;
  final IconData? icon;
  final bool highlighted;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: TextButton(
            clipBehavior: Clip.antiAlias,
            style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(highlighted ? Theme.of(context).highlightColor : null)),
            child: Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: EdgeInsets.all(2.0),
                    child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Icon(
                          icon!,
                          weight: 3,
                        )),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(alignment: Alignment.centerLeft, child: Text(text)),
                ),
              ],
            ),
            onPressed: () => onTap?.call()),
      ),
    );
  }
}
