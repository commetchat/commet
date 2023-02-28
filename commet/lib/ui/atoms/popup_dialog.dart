import 'package:flutter/material.dart';

class PopupDialog {
  static void Show(BuildContext context, Widget content, {String? title, double width = 400, double height = 400}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "POPUP_DIALOG",
      barrierColor: Colors.black.withAlpha(128),
      pageBuilder: (context, _, __) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.all(8),
          title: title != null ? Text(title) : null,
          content: Container(
            height: height,
            width: width,
            child: content,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
