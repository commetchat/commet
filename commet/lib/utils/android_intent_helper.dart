import 'package:commet/utils/custom_uri.dart';
import 'package:receive_intent/receive_intent.dart';

class AndroidIntentHelper {
  static CustomURI? getUriFromIntent(Intent? intent) {
    var key = "flutter_shortcuts";

    if (intent?.action == "SELECT_NOTIFICATION") {
      key = "payload";
    }

    if (intent?.extra?.containsKey(key) == true) {
      var uri = CustomURI.parse(intent!.extra![key]);
      return uri;
    }

    return null;
  }
}
