import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TinyPill extends StatelessWidget {
  const TinyPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).colorScheme.primary),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: tiamat.Text.tiny(text),
        ),
      ),
    );
  }
}
