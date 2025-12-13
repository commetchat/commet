import 'package:commet/utils/link_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class LinkSpan {
  static InlineSpan create(String text,
      {required BuildContext context,
      required String clientId,
      destination,
      TextStyle? style}) {
    var color = Theme.of(context).extension<ExtraColors>()?.linkColor ??
        Theme.of(context).colorScheme.primary;

    return TextSpan(
        text: text,
        style: (style ?? const TextStyle())
            .copyWith(color: color, decorationColor: color),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (destination != null) {
              LinkUtils.open(destination, clientId: clientId);
            }
          });
  }
}
