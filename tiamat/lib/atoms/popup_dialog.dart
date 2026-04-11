import 'package:flutter/material.dart';
import 'package:tiamat/atoms/button.dart';
import 'package:tiamat/config/config.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: 'Default', type: PopupDialog)
Widget wbpopupDialog(BuildContext context) {
  return Container(
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.largeTitle("Example Content"),
              tiamat.Text.labelEmphasised(
                  "Random stuff here to put a dialog over"),
              tiamat.Text.body(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
              tiamat.Text.body(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
            ],
          ),
        ),
        Container(
          color: PopupDialog.barrierColor,
          child: Center(
              child: PopupDialog(
            title: "Hello!",
            content: tiamat.Text.body(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
          )),
        ),
      ],
    ),
  );
}

class PopupDialog extends StatelessWidget {
  const PopupDialog(
      {super.key,
      required this.title,
      required this.content,
      this.contentPadding = 8,
      this.width = null,
      this.height = null});
  final String? title;
  final double? width;
  final double? height;
  final double contentPadding;
  final Widget content;

  static Color barrierColor = Colors.black.withAlpha(128);

  static Future<T?> show<T extends Object?>(BuildContext context,
      {required Widget content,
      String? title,
      double? width,
      double? height,
      double contentPadding = 8,
      bool barrierDismissible = true}) {
    return showGeneralDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: "POPUP_DIALOG",
        barrierColor: barrierColor,
        pageBuilder: (context, _, __) {
          return Theme(
            data: Theme.of(context),
            child: PopupDialog(
              title: title,
              content: content,
              width: width,
              height: height,
              contentPadding: contentPadding,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.all(contentPadding),
      title: title == null
          ? null
          : Row(
              children: [
                Text(title!),
              ],
            ),
      content: content,
    );
  }
}
