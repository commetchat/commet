import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Default', type: TextInput)
Widget wbTextInput(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextInput(
            placeholder: "Some placeholder text",
          ),
        ),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'With Icon', type: TextInput)
Widget wbTextInputWithIcon(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextInput(
            placeholder: "Search...",
            icon: material.Icon(material.Icons.search),
          ),
        ),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'Multiline', type: TextInput)
Widget wbTextInputMultiline(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextInput(
            maxLines: 5,
            placeholder: "Write something interesting...",
          ),
        ),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'Multiline with Icon', type: TextInput)
Widget wbTextInputMultilineWithIcon(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextInput(
            maxLines: 5,
            placeholder: "Write something interesting...",
            icon: material.Icon(material.Icons.edit_note),
          ),
        ),
      ],
    ),
  );
}

class TextInput extends StatefulWidget {
  const TextInput(
      {this.placeholder,
      this.icon,
      this.controller,
      this.maxLines,
      this.label,
      this.minLines,
      this.maxLength,
      super.key});
  final String? placeholder;
  final Widget? icon;
  final TextEditingController? controller;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? label;
  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return material.TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      cursorColor: material.Theme.of(context).highlightColor,
      decoration: material.InputDecoration(
          label: widget.label != null ? Text(widget.label!) : null,
          fillColor: material.Colors.red,
          border: material.OutlineInputBorder(),
          hintText: widget.placeholder,
          icon: widget.icon),
    );
  }
}
