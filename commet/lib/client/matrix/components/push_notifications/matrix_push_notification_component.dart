import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:matrix/matrix.dart';

class MatrixPushNotificationComponent
    implements PushNotificationComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixPushNotificationComponent(this.client);

  @override
  Future<void> ensurePushNotificationsRegistered(
      String pushKey, String pushServer,
      {Map<String, dynamic>? extraData}) async {
    var matrixClient = client.getMatrixClient();

    var pushers = await matrixClient.getPushers();

    // Check if there is already a pusher registered with this key
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
        deviceDisplayName: "test",
        kind: "http",
        lang: "en");

    await matrixClient.postPusher(pusher, append: true);
  }
}
