import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/text.dart' as tiamat;

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Default', type: Seperator)
Widget wbseperatorUseCase(BuildContext context) {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: 300,
      height: 500,
      child: Column(
        children: const [
          tiamat.Text.body(
            "Hello!",
          ),
          Seperator(),
          tiamat.Text.body(
            "World!",
          )
        ],
      ),
    ),
  );
}

class Seperator extends StatelessWidget {
  const Seperator({super.key, this.padding = 8});
  final double padding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: const material.Divider(
        height: 1,
      ),
    );
  }
}
