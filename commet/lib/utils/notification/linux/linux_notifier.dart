import 'package:commet/utils/notification/notifier.dart';
import 'package:desktop_notifications/desktop_notifications.dart';

import '../notification_manager.dart';

class LinuxNotifier extends Notifier {
  @override
  bool get hasPermission => true;

  static NotificationsClient client = NotificationsClient();

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<void> notifyInternal(NotificationContent notification) async {
    await client.notify(notification.title, body: notification.content);
  }
}
