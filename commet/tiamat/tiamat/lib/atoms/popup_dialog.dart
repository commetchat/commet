import 'package:flutter/material.dart';
import 'package:tiamat/atoms/button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@WidgetbookUseCase(name: 'Default', type: PopupDialog)
Widget wbpopupDialog(BuildContext context) {
  return Center(
      child: SizedBox(
          width: 200,
          height: 40,
          child: Button(
            text: "Click Me!",
            onTap: () {
              PopupDialog.show(context, const tiamat.Text.body("Hello!"));
            },
          )));
}

class PopupDialog {
  static void show(BuildContext context, Widget content, {String? title, double width = 400, double height = 400}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "POPUP_DIALOG",
      barrierColor: Colors.black.withAlpha(128),
      pageBuilder: (context, _, __) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.all(8),
          title: title != null ? Text(title) : null,
          content: SizedBox(
            height: height,
            width: width,
            child: content,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
