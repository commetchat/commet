import 'package:commet/config/build_config.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:flutter/material.dart' as m;

class AdaptiveDialog {
  static void show(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    required String title,
    bool dismissible = true,
    double initialHeightMobile = 0.5,
  }) {
    if (BuildConfig.DESKTOP) {
      PopupDialog.show(context,
          content: builder(context),
          title: title,
          barrierDismissible: dismissible);
    }

    if (BuildConfig.MOBILE) {
      m.showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: dismissible,
        backgroundColor:
            m.Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
        builder: (context) {
          return SingleChildScrollView(
              child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: builder(context),
              ),
            ),
          ));
        },
      );
    }
  }
}
