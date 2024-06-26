import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class AdaptiveDialog {
  static Future<T?> show<T extends Object?>(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    String? title,
    bool scrollable = true,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) async {
    if (Layout.desktop) {
      return PopupDialog.show<T>(context,
          content: scrollable
              ? SingleChildScrollView(child: builder(context))
              : builder(context),
          title: title,
          barrierDismissible: dismissible);
    }

    return m.showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      elevation: 0,
      isDismissible: dismissible,
      backgroundColor: m.Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (context) {
        return SingleChildScrollView(
            child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ScaledSafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: tiamat.Text.largeTitle(title),
                    ),
                  Center(child: builder(context)),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  static Future<bool?> confirmation(BuildContext context,
      {String prompt = "Are you sure?",
      String title = "Confirmation",
      String confirmationText = "Yes",
      String cancelText = "No",
      bool dangerous = false}) {
    return show<bool?>(context, builder: (context) {
      return SizedBox(
        width: Layout.desktop ? 500 : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Markdown(
                  shrinkWrap: true,
                  data: prompt,
                ),
              ),
              SizedBox(
                height: 40,
                child: tiamat.Button(
                  type: dangerous ? ButtonType.danger : ButtonType.primary,
                  text: confirmationText,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              tiamat.Button.secondary(
                text: cancelText,
                onTap: () => Navigator.pop(context, false),
              )
            ],
          ),
        ),
      );
    }, title: title);
  }
}
