import 'package:commet/config/build_config.dart';
import 'package:commet/utils/orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class AdaptiveDialog {
  static bool showDesktopVersion(BuildContext context) =>
      BuildConfig.DESKTOP ||
      (BuildConfig.WEB &&
          OrientationUtils.getCurrentOrientation(context) ==
              Orientation.landscape);

  static Future<T?> show<T extends Object?>(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    required String title,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) async {
    if (showDesktopVersion(context)) {
      return PopupDialog.show<T>(context,
          content: builder(context),
          title: title,
          barrierDismissible: dismissible);
    }

    return m.showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      backgroundColor:
          m.Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
      builder: (context) {
        return SingleChildScrollView(
            child: Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
        width: showDesktopVersion(context) ? 500 : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
