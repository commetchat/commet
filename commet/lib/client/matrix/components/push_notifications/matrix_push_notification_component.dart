import 'dart:convert';

import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart';

class MatrixPushNotificationComponent
    implements PushNotificationComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixPushNotificationComponent(this.client);

  @override
  Future<void> ensurePushNotificationsRegistered(
      String pushKey, String pushServer, String deviceName,
      {Map<String, dynamic>? extraData}) async {
    var matrixClient = client.getMatrixClient();

    var pushers = await matrixClient.getPushers();

    if (pushers != null &&
        pushers.any((element) => element.pushkey == pushKey)) {
      return;
    }

    var pusher = Pusher(
        appId: "chat.commet.commetapp.android",
        pushkey: pushKey,
        appDisplayName: BuildConfig.appName,
        data: PusherData(
          format: "event_id_only",
          url: Uri.parse(pushServer),
          additionalProperties: extraData ?? {},
        ),
        deviceDisplayName: deviceName,
        kind: "http",
        lang: "en");

    await matrixClient.postPusher(pusher, append: true);
  }

  Future<void> cleanOldPushers(
      String? currentPushKey, String deviceName) async {
    var matrixClient = client.getMatrixClient();
    var pushers = await matrixClient.getPushers();

    // Check for stale pushers
    if (pushers != null) {
      for (var pusher in pushers) {
        if (pusher.deviceDisplayName == deviceName &&
            pusher.pushkey != currentPushKey) {
          await matrixClient.deletePusher(pusher);
        }
      }
    }
  }

  @override
  void postLoginInit() async {
    var notifier = notificationManager.notifier;
    var key = await notifier?.getToken();
    var mxClient = client.getMatrixClient();
    var extraData = notifier?.extraRegistrationData();
    var name = mxClient.clientName;

    await cleanOldPushers(key, name);

    if (key == null) {
      return;
    }

    await ensurePushNotificationsRegistered(
        key, "http://push.commet.chat/_matrix/push/v1/notify", name,
        extraData: extraData);
  }
}
