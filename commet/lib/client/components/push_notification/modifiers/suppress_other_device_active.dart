import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix_api_lite/generated/model.dart' show Device;

class NotificationModifierSuppressOtherActiveDevice
    implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (content is! MessageNotificationContent) {
      return content;
    }

    if (clientManager == null) {
      Log.w(
          "Suppressing notifications for background client is not currently supported");
      return content;
    }

    var clients = clientManager!.clients
        .where((element) => element.hasRoom(content.roomId));

    for (var client in clients) {
      List<Device>? devices;
      String? thisDeviceId;
      if (client is MatrixClient) {
        devices = await client.getMatrixClient().getDevices();
        thisDeviceId = client.getMatrixClient().deviceID;
      }

      if (client is MatrixBackgroundClient) {
        devices = await client.api.getDevices();
        thisDeviceId = client.deviceId;
      }

      if (devices == null) continue;

      for (var device in devices) {
        if (device.lastSeenTs == null) continue;
        if (device.deviceId == thisDeviceId) {
          continue;
        }

        var time = DateTime.fromMillisecondsSinceEpoch(device.lastSeenTs!);

        var diff = DateTime.now().difference(time);

        if (diff.inMinutes < 10) {
          Log.i(
              "Suppressing this notification because there is another device which has been active recently!\nThe device which was active is: ${device.displayName} : ${device.deviceId}");

          content.priority = NotificationPriority.low;
          return content;
        }
      }
    }
    return content;
  }
}
