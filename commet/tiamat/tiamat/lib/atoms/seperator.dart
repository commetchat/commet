import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/text.dart' as tiamat;

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Default', type: Seperator)
Widget wb_seperatorUseCase(BuildContext context) {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: 300,
      height: 500,
      child: Column(
        children: [
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
  const Seperator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: material.Divider(
        height: 1,
      ),
    );
  }
}
