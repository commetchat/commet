import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/links/smart_link_handler.dart';
import 'package:commet/utils/links/tracking_parameters_cleaner.dart';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtils {
  static Future<void> open(Uri uri,
      {String? clientId,
      String? contextRoomId,
      BuildContext? context,
      bool filterTrackingParameters = true}) async {
    if (context != null) {
      ErrorUtils.tryRun(context, () async {
        await _open(uri,
            clientId: clientId,
            context: context,
            contextRoomId: contextRoomId,
            filterTrackingParameters: filterTrackingParameters);
      });
    } else {
      await _open(uri,
          clientId: clientId,
          context: context,
          contextRoomId: contextRoomId,
          filterTrackingParameters: filterTrackingParameters);
    }
  }

  static Future<void> _open(Uri uri,
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

    if (context != null) {
      var handler = await SmartLinkHandling.getHandler(openUrl);

      if (handler != null) {
        for (var executor in handler.executors) {
          if (await executor.canHandleLink(uri)) {
            var confirm = await AdaptiveDialog.confirmation(context,
                prompt: executor.getDescription(uri),
                title: "Open in ${handler.appName}?");

            if (confirm == true) {
              executor.execute(openUrl);
            }

            if (confirm == false) {
              launchUrl(openUrl, mode: LaunchMode.externalApplication);
            }

            return;
          }
        }
      }
    }

    var cleanedUrl =
        await UrlTrackingParametersCleaner.cleanTrackingParameters(uri);

    if (cleanedUrl.toString() != uri.toString()) {
      if (context != null) {
        var confirm = await AdaptiveDialog.confirmation(context,
            title: "Open Link",
            confirmationText: "Open",
            cancelText: "Open Original Link",
            prompt:
                "This link contained trackers, which have been removed. Open `$cleanedUrl`?");

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
                prompt: "Open `$uri` in your web browser?") !=
            true) {
          return;
        }
      }
    }

    Log.d("Opening Link: $openUrl");

    launchUrl(openUrl, mode: LaunchMode.externalApplication);
  }
}
