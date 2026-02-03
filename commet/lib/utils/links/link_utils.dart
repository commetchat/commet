import 'dart:convert';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/links/tracking_parameters.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix_api_lite.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtils {
  static Future<void> open(Uri uri,
      {String? clientId,
      String? contextRoomId,
      BuildContext? context,
      bool filterTrackingParameters = true}) async {
    if (uri.host == "matrix.to") {
      var result = MatrixClient.parseMatrixLink(uri);

      if (result != null && clientId != null) {
        switch (result.$1) {
          case MatrixLinkType.room:
            return EventBus.openRoom.add((result.$3, clientId));
          case MatrixLinkType.user:
            return EventBus.openUserProfile
                .add((result.$2, clientId, contextRoomId));
          case MatrixLinkType.roomAlias:
            return EventBus.openRoom.add((result.$3, clientId));
        }
      }
    }

    if (!(uri.scheme == "http" || uri.scheme == "https")) {
      return;
    }

    var openUrl = uri;

    var cleanedUrl =
        await UrlTrackingParametersCleaner.cleanTrackingParameters(uri);

    if (cleanedUrl.toString() != uri.toString()) {
      if (context != null) {
        var confirm = await AdaptiveDialog.confirmation(context,
            title: "Open Link",
            confirmationText: "Open",
            cancelText: "Open Original Link",
            prompt:
                "This link contained trackers, which have been removed. Navigate to '$cleanedUrl'?");

        if (confirm == null) return;

        if (confirm == true) {
          openUrl = cleanedUrl;
        }
      }
    } else {
      if (context != null) {
        if (await AdaptiveDialog.confirmation(context,
                title: "Open Link",
                confirmationText: "Open",
                cancelText: "Cancel",
                prompt: "Navigate to '$uri'?") !=
            true) {
          return;
        }
      }
    }

    Log.d("Opening Link: $openUrl");

    launchUrl(openUrl, mode: LaunchMode.externalApplication);
  }
}
