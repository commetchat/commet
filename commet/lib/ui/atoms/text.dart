import 'package:flutter/material.dart' as material;
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';

import '../../config/app_config.dart';

class Text extends StatelessWidget {
  const Text(this.text, {super.key, required this.style});
  final TextStyle style;
  final String text;

  Text.ui(this.text, BuildContext context, {Key? key})
      : style = material.Theme.of(context).textTheme.bodySmall!,
        super(key: key);

  Text.body(this.text, BuildContext context, {Key? key})
      : style = material.Theme.of(context).textTheme.bodyMedium!,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return material.Text(
      text,
      style: style,
      textScaleFactor: getUiScale(),
    );
  }
}
