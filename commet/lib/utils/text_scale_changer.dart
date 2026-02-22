import 'package:flutter/material.dart';

class TextScaleChanger extends StatefulWidget {
  const TextScaleChanger({required this.child, super.key});
  final Widget child;

  @override
  State<TextScaleChanger> createState() => _TextScaleChangerState();
}

class _TextScaleChangerState extends State<TextScaleChanger> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
        data:
            MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2.0)),
        child: widget.child);
  }
}
