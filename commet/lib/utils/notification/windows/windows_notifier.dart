import 'dart:async';
import 'package:commet/utils/notification/notifier.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import '../notification_manager.dart';

class WindowsNotifier extends Notifier {
  @override
  bool get hasPermission => true;

  static NotificationsClient client = NotificationsClient();

  static Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<void> notifyInternal(NotificationContent notification) async {}
}
