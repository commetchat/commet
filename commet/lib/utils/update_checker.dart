import 'dart:convert';

import 'package:commet/client/alert.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/link_utils.dart';

import 'package:http/http.dart' as http;

class UpdateChecker {
  static bool foundUpdate = false;

  static Future<void> checkForUpdates() async {
    if (foundUpdate) return;

    if (!shouldCheckForUpdates) {
      return;
    }

    const key = "chat.commet.published_version";

    var url = Uri.parse(
        "https://data.commet.chat/_matrix/federation/v1/query/profile?user_id=@updates:data.commet.chat");

    var response = await http.get(url);

    if (response.statusCode == 200) {
      foundUpdate = true;
    }

    Log.i("Got update data: ${response.body}");

    var fields = jsonDecode(response.body) as Map<String, dynamic>;

    if (fields.containsKey(key)) {
      var date = fields["chat.commet.build_date_ms"];

      var val = int.parse(date);
      var time = DateTime.fromMillisecondsSinceEpoch(val);

      if (time.isAfter(BuildConfig.BUILD_DATE)) {
        var tag = fields[key];
        clientManager!.alertManager.addAlert(Alert(AlertType.info,
            messageGetter: () =>
                "There is a newer version of Commet available: ${tag}",
            titleGetter: () => "Update Available",
            action: doUpdateAction));
      } else {
        Log.i(
            "Found an update, but it's build date is not after the current build, current: ${BuildConfig.BUILD_DATE.millisecondsSinceEpoch} remote: ${time.millisecondsSinceEpoch}");
      }

      return;
    }
  }

  static bool get shouldCheckForUpdates {
    if (PlatformUtils.isWeb) {
      return false;
    }

    if (preferences.checkForUpdates != true) {
      return false;
    }

    if (BuildConfig.VERSION_TAG == "v0.0.0-artifact") {
      return false;
    }

    return true;
  }

  static doUpdateAction() {
    LinkUtils.open(Uri.parse("https://github.com/commetchat/commet/releases"));
  }
}
