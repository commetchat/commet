import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
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

    var pushers = await matrixClient.getPushers();

    if (pushers != null &&
        pushers.any((element) => element.pushkey == pushKey)) {
      return;
    }

    var appId = PlatformUtils.appID;

    var pusher = Pusher(
        appId: appId,
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
        if (pusher.appId == PlatformUtils.appID &&
            ((pusher.deviceDisplayName != deviceName &&
                    pusher.pushkey == currentPushKey) ||
                (pusher.deviceDisplayName == deviceName &&
                    (pusher.pushkey != currentPushKey ||
                        pusher.data.url != pushGateway)))) {
          // 2 cases here:
          //   - existing pusher with the same key (i.e. same device for
          //     receiving notifications) but different device name, so
          //     a change of some sort has happened.
          //   - Same name but different key or different gateway
          // But always we only want to remove the commet pushers.
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

    if (PlatformUtils.isIOS) {
      name = "iPhone";
    }

    var uri = Uri.parse(preferences.pushGateway);
    if (uri.hasScheme == false) {
      uri = Uri.https(preferences.pushGateway);
    }

    uri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: "/_matrix/push/v1/notify");

    await cleanOldPushers(key, name, uri);

    if (key == null) {
      Log.w("Device key is null");
      return;
    }

    Log.i("Registering pusher");
    await ensurePushNotificationsRegistered(key, uri, name,
        extraData: extraData);
  }

  @override
  void postLoginInit() async {
    updatePushers();
  }
}
