import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/widgets.dart';

class ErrorUtils {
  static Future<void> tryRun(
      BuildContext context, Future<void> function()) async {
    try {
      await function();
    } catch (e, s) {
      Log.onError(e, s);
      AdaptiveDialog.showError(context, e, s);
    }
  }
}
