import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtils {
  static void open(Uri uri, {String? clientId, String? contextRoomId}) {
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

    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
