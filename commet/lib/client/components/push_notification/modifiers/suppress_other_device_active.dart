import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:flutter/foundation.dart';

class NotificationModifierSuppressOtherActiveDevice
    implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (content is! MessageNotificationContent) {
      return content;
    }

    var clients = clientManager!.clients
        .where((element) => element.hasRoom(content.roomId));

    for (var client in clients) {
      if (client is! MatrixClient) continue;

      var mxClient = client.getMatrixClient();
      var devices = await mxClient.getDevices();
      if (devices == null) continue;

      for (var device in devices) {
        if (device.lastSeenTs == null) continue;
        if (device.deviceId == mxClient.deviceID) {
          continue;
        }

        var time = DateTime.fromMillisecondsSinceEpoch(device.lastSeenTs!);

        var diff = DateTime.now().difference(time);

        if (diff.inMinutes < 10) {
          if (kDebugMode) {
            print(
                "Suppressing this notification because there is another device which has been active recently!");
            print(
                "The device which was active is: ${device.displayName} : ${device.deviceId}");
          }
          content.priority = NotificationPriority.low;
          return content;
        }
      }
    }
    return content;
  }
}
