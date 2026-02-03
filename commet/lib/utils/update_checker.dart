import 'dart:convert';
import 'dart:io';

import 'package:commet/client/alert.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'package:http/http.dart' as http;

class UpdateChecker {
  static bool foundUpdate = false;

  static Future<void> checkForUpdates() async {
    if (foundUpdate) return;

    if (!shouldCheckForUpdates) {
      return;
    }

    if (preferences.checkForUpdates != true) {
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

      var canAutoUpdate = fields["chat.commet.auto_update"] == "true";
      Log.i("Supports auto update: $canAutoUpdate");
      if (time.isAfter(BuildConfig.BUILD_DATE)) {
        var tag = fields[key];
        clientManager!.alertManager.addAlert(Alert(AlertType.info,
            messageGetter: () =>
                "There is a newer version of Commet available: ${tag}",
            titleGetter: () => "Update Available",
            action: (context) => doUpdateAction(context, canAutoUpdate)));
      } else {
        Log.i(
            "Found an update, but it's build date is not after the current build, current: ${BuildConfig.BUILD_DATE.toString()} remote: ${time.toString()}");
      }

      return;
    }
  }

  static bool get shouldCheckForUpdates {
    if (PlatformUtils.isWeb) {
      return false;
    }

    if (BuildConfig.VERSION_TAG == "v0.0.0-artifact") {
      return false;
    }

    return true;
  }

  static doUpdateAction(BuildContext context, bool canAutoUpdate) async {
    if (PlatformUtils.isWindows) {
      windowsUpdateAction(context, canAutoUpdate);
    }

    if (PlatformUtils.isAndroid) {
      LinkUtils.open(
        Uri.parse("https://commet.chat/install/android/"),
        context: context,
      );
    }

    if (PlatformUtils.isLinux) {
      LinkUtils.open(Uri.parse("https://commet.chat/install/linux/"),
          context: context);
    }
  }

  static windowsUpdateAction(BuildContext context, bool canAutoUpdate) async {
    var exe = Platform.resolvedExecutable;

    var installPath = path.dirname(exe);

    var installerPath =
        path.join(installPath, "installer", "commet-installer.exe");

    Log.i("Installed at: $installerPath");

    if (await File(installerPath).exists() && canAutoUpdate) {
      var confirmation = await AdaptiveDialog.confirmation(context,
          prompt: "Would you like to run the update installer?");

      if (confirmation == true) {
        await ErrorUtils.tryRun(context, () async {
          Log.i("Found installer, doing automatic update");

          for (var client in clientManager!.clients) {
            await client.close();
          }

          Process.run(
              installerPath,
              [
                "--command",
                "update",
              ],
              runInShell: true);

          // TODO: not this
          await Future.delayed(Duration(seconds: 1));
        });

        exit(0);
      }

      if (confirmation == null) return;
    }

    LinkUtils.open(Uri.parse("https://commet.chat/install/windows/"),
        context: context);
  }
}
