import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

abstract class PushNotificationComponent<T extends Client>
    implements Component<T>, NeedsPostLoginInit {
  Future<void> ensurePushNotificationsRegistered(
      String pushKey, Uri pushServer, String deviceName,
      {Map<String, dynamic>? extraData});

  Future<void> updatePushers();
}
