import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import './text.dart' as t;

enum Names { alice, bob, charlie }

@WidgetbookUseCase(name: 'Default', type: RadioButton)
Widget wbRadioButton(BuildContext context) {
  return Center(
    child: Column(
      children: [
        RadioButton(
          value: Names.alice,
          groupValue: Names.bob,
          onChanged: (_) {},
          text: "Alice",
          icon: Icons.abc,
        ),
        RadioButton(
          value: Names.bob,
          groupValue: Names.bob,
          onChanged: (_) {},
          text: "Bob",
          icon: Icons.abc,
        ),
        RadioButton(
          value: Names.charlie,
          groupValue: Names.bob,
          onChanged: (_) {},
          text: "Charlie",
          icon: Icons.abc,
        ),
      ],
    ),
  );
}

class RadioButton<T> extends StatelessWidget {
  const RadioButton(
      {super.key,
      required this.value,
      required this.groupValue,
      required this.onChanged,
      required this.text,
      this.icon});
  final T value;
  final T groupValue;
  final void Function(T? value)? onChanged;
  final IconData? icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    var color =
        value == groupValue ? Theme.of(context).colorScheme.primary : null;
    return RadioListTile<T>(
      value: value,
      title: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
              child: Icon(
                icon,
                color: color,
              ),
            ),
          t.Text.labelEmphasised(
            text,
            color: color,
          )
        ],
      ),
      groupValue: groupValue,
      tileColor: Colors.transparent,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
