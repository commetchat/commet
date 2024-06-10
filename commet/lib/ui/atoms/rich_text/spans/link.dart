import 'package:commet/utils/link_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';

class LinkSpan {
  static InlineSpan create(String text,
      {required BuildContext context, destination, TextStyle? style}) {
    return TextSpan(
        text: text,
        style: (style ?? const TextStyle()).copyWith(
            color: Theme.of(context).colorScheme.primary,
            decorationColor: Theme.of(context).colorScheme.primary),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (destination != null) {
              LinkUtils.open(destination);
            }
          });
  }
}
