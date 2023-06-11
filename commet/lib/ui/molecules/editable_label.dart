import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import '../atoms/tooltip.dart';

class EditableLabel extends StatefulWidget {
  const EditableLabel({
    super.key,
    required this.initialText,
    this.type = TextType.label,
    this.onTextConfirmed,
    this.changeTooltip = "Change text",
    this.confirmTooltip = "Confirm",
  });
  final TextType type;
  final Function(String? newText)? onTextConfirmed;
  final String initialText;
  final String changeTooltip;
  final String confirmTooltip;

  @override
  State<EditableLabel> createState() => _EditableLabelState();
}

class _EditableLabelState extends State<EditableLabel> {
  bool editingName = false;
  late TextEditingController nameController;
  late String text;

  @override
  void initState() {
    text = widget.initialText;
    nameController = TextEditingController(text: text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [nameEditor(), toggleNameEdit()],
    );
  }

  Widget nameEditor() {
    return material.Material(
        color: material.Colors.transparent,
        child: editingName
            ? SizedBox(
                width: 200,
                child: TextInput(
                  maxLines: 1,
                  controller: nameController,
                ),
              )
            : tiamat.Text(
                text,
                type: widget.type,
              ));
  }

  Widget toggleNameEdit() {
    return editingName
        ? Tooltip(
            text: widget.confirmTooltip,
            preferredDirection: AxisDirection.right,
            child: tiamat.IconButton(
              icon: material.Icons.check,
              onPressed: () {
                var name = nameController.text.trim();
                if (name.isEmpty) return;

                widget.onTextConfirmed?.call(name);

                setState(() {
                  text = nameController.text;
                  editingName = false;
                });
              },
            ),
          )
        : Tooltip(
            text: widget.changeTooltip,
            preferredDirection: AxisDirection.right,
            child: tiamat.IconButton(
              icon: material.Icons.edit,
              onPressed: () {
                setState(() {
                  editingName = true;
                });
              },
            ),
          );
  }
}
