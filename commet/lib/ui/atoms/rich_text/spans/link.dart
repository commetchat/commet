import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';

class LinkSpan {
  static InlineSpan create(String text, {Uri? destination, TextStyle? style}) {
    return TextSpan(
        text: text,
        style:
            (style ?? TextStyle()).copyWith(color: ThemeDarkColors.primary, decorationColor: ThemeDarkColors.primary),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            print("Link Tapped: ${destination.toString()}");
          });
  }
}
