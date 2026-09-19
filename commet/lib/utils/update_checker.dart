import 'dart:convert';

import 'package:commet/client/alert.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;

/// Checks for a newer roscord release on GitHub Releases.
///
/// This goes through the unauthenticated GitHub API. That is rate limited to 60
/// requests per hour per IP, which is ample for one request per launch on a
/// desktop install, but it is the reason [shouldCheckForUpdates] exists and the
/// reason the result is cached for the process lifetime ([foundUpdate]).
///
/// Note that `releases/latest` excludes prereleases, so a release tagged as a
/// prerelease is invisible here by design.
class UpdateChecker {
  static bool foundUpdate = false;

  /// The project whose releases we check.
  static const String releasesApiUrl =
      "https://api.github.com/repos/PondLabs/roscord/releases/latest";

  /// Where the "View release" action sends the user.
  static const String releasesPageUrl =
      "https://github.com/PondLabs/roscord/releases/latest";

  static String get labelUpdateAvailable => Intl.message("Update Available",
      name: "labelUpdateAvailable",
      desc: "Label for the the info popup when an update is available");

  static String descriptionUpdateAvailable(String version) => Intl.message(
      "There is a newer version of roscord available: ${version}. Tap to open the release page.",
      name: "descriptionUpdateAvailable",
      args: [version],
      desc:
          "describes the update, showing the version code for the available update. The alert has no button, so the text says what tapping it does");

  static Future<void> checkForUpdates() async {
    if (foundUpdate) return;

    if (!shouldCheckForUpdates) {
      return;
    }

    if (preferences.checkForUpdates.value != true) {
      return;
    }

    String? latest;
    try {
      var response = await http.get(Uri.parse(releasesApiUrl), headers: {
        // The API rejects requests without a User-Agent.
        "Accept": "application/vnd.github+json",
      });

      if (response.statusCode != 200) {
        Log.i("Update check failed: HTTP ${response.statusCode}");
        return;
      }

      var data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return;

      latest = data["tag_name"] as String?;
    } catch (e, s) {
      // A failed update check is never worth surfacing to the user, and it must
      // not break startup.
      Log.onError(e, s);
      return;
    }

    if (latest == null || latest.isEmpty) return;

    foundUpdate = true;

    if (!isNewer(latest, BuildConfig.VERSION_TAG)) {
      Log.i("Up to date: running ${BuildConfig.VERSION_TAG}, latest $latest");
      return;
    }

    Log.i("Found update: ${BuildConfig.VERSION_TAG} -> $latest");

    clientManager!.alertManager.addAlert(Alert(AlertType.info,
        messageGetter: () => descriptionUpdateAvailable(latest!),
        titleGetter: () => labelUpdateAvailable,
        action: doUpdateAction));
  }

  /// True when [candidate] is a strictly newer version than [current].
  ///
  /// Both are expected as `vMAJOR.MINOR.PATCH` (the format of the git tags and
  /// of [BuildConfig.VERSION_TAG]) but any leading `v` and any trailing
  /// pre-release/build suffix are tolerated: only the leading numeric dotted
  /// run is compared, so `v1.2.3-rc1` compares as `1.2.3`.
  ///
  /// Returns false when either side has no parseable version, so a local build
  /// with the default `VERSION_TAG` of `development` never reports an update.
  static bool isNewer(String candidate, String current) {
    var a = parseVersion(candidate);
    var b = parseVersion(current);

    if (a == null || b == null) return false;

    var length = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      var x = i < a.length ? a[i] : 0;
      var y = i < b.length ? b[i] : 0;

      if (x != y) return x > y;
    }

    return false;
  }

  /// The leading numeric dotted run of [tag] as a list of ints, or null when
  /// there is none.
  static List<int>? parseVersion(String tag) {
    var match = RegExp(r"(\d+(?:\.\d+)*)").firstMatch(tag);

    if (match == null) return null;

    return match.group(1)!.split(".").map(int.parse).toList();
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

  /// Everything an update does today is open the release page.
  ///
  /// roscord ships as archives (a zip on Windows, a tar.gz on Linux) rather
  /// than through an installer, and two of the four Linux packages (deb,
  /// flatpak) are owned by a package manager. Replacing the running binary is
  /// therefore not a thing we can do correctly on every platform, so this
  /// deliberately stops at telling the user and taking them to the download.
  static doUpdateAction(BuildContext context) async {
    LinkUtils.open(Uri.parse(releasesPageUrl), context: context);
  }
}
