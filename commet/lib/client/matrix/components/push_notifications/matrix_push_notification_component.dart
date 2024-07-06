import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart';

class MatrixPushNotificationComponent
    implements PushNotificationComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixPushNotificationComponent(this.client);

  @override
  Future<void> ensurePushNotificationsRegistered(
      String pushKey, Uri pushServer, String deviceName,
      {Map<String, dynamic>? extraData}) async {
    var matrixClient = client.getMatrixClient();

    Log.i("Current push key: $pushKey");

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
          url: pushServer,
          additionalProperties: extraData ?? {},
        ),
        deviceDisplayName: deviceName,
        kind: "http",
        lang: "en");

    await matrixClient.postPusher(pusher, append: true);
  }

  Future<void> cleanOldPushers(
      String? currentPushKey, String deviceName, Uri pushGateway) async {
    var matrixClient = client.getMatrixClient();
    var pushers = await matrixClient.getPushers();

    // Check for stale pushers
    if (pushers != null) {
      for (var pusher in pushers) {
        if (pusher.deviceDisplayName == deviceName &&
            (pusher.pushkey != currentPushKey ||
                pusher.data.url != pushGateway)) {
          await matrixClient.deletePusher(pusher);
        }
      }
    }
  }

  @override
  Future<void> updatePushers() async {
    if (NotificationManager.notifierLoading != null) {
      await NotificationManager.notifierLoading;
    }
    var notifier = NotificationManager.notifier;
    var key = await notifier?.getToken();
    var mxClient = client.getMatrixClient();
    var extraData = notifier?.extraRegistrationData();
    var name = mxClient.clientName;
    var uri = Uri.https(preferences.pushGateway, "/_matrix/push/v1/notify");

    await cleanOldPushers(key, name, uri);

    if (key == null) {
      return;
    }

    await ensurePushNotificationsRegistered(key, uri, name,
        extraData: extraData);
  }

  @override
  void postLoginInit() async {
    updatePushers();
  }
}
