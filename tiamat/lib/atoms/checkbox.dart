import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter/material.dart' as material;

@WidgetbookUseCase(name: 'Large', type: Checkbox)
Widget wbCheckBox(BuildContext context) {
  return Center(
      child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Checkbox(
        value: false,
      ),
      Seperator(),
      Checkbox(
        value: true,
      )
    ],
  ));
}

class Checkbox extends StatelessWidget {
  const Checkbox({super.key, this.value, this.onChanged});
  final bool? value;
  final Function(bool? value)? onChanged;

  @override
  Widget build(BuildContext context) {
    return material.Checkbox(
      value: value,
      onChanged: (newValue) {
        onChanged?.call(newValue);
      },
    );
  }
}
