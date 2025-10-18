import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class AdaptiveTextDialog {
  static Future<String?> show(
    BuildContext context, {
    String? title,
    String? placeholder,
    String? defaultText,
    String? description,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) async {
    final result = await AdaptiveDialog.show<String>(context, title: title,
        builder: (context) {
      return AdaptiveTextDialogWidget(
        description: description,
        defaultText: defaultText,
        placeholder: placeholder,
      );
    });

    return result;
  }
}

class AdaptiveTextDialogWidget extends StatefulWidget {
  const AdaptiveTextDialogWidget(
      {super.key, this.placeholder, this.description, this.defaultText});
  final String? placeholder;
  final String? defaultText;
  final String? description;
  @override
  State<AdaptiveTextDialogWidget> createState() =>
      _AdaptiveTextDialogWidgetState();
}

class _AdaptiveTextDialogWidgetState extends State<AdaptiveTextDialogWidget> {
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: widget.defaultText);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.description != null)
              SizedBox(
                width: 400,
                child: tiamat.Text.labelLow(
                  widget.description!,
                ),
              ),
            SizedBox(
              height: 10,
            ),
            tiamat.TextInput(
              placeholder: widget.placeholder,
              controller: controller,
            ),
            SizedBox(
              height: 10,
            ),
            tiamat.Button(
              text: "Submit",
              onTap: () => Navigator.of(context).pop(controller.text),
            )
          ],
        ),
      ),
    );
  }
}
