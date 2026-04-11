import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TinyPill extends StatelessWidget {
  const TinyPill(this.text, {this.background, this.foreground, super.key});
  final String text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: background ?? Theme.of(context).colorScheme.primary,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: tiamat.Text.tiny(
            text,
            color: foreground ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
