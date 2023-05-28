import 'package:commet/ui/navigation/navigation_signals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_manager.dart';

abstract class Notifier {
  @protected
  Future<void> notifyInternal(NotificationContent notification);

  Future<void> notify(NotificationContent notification) async {
    if (!hasPermission) {
      await requestPermission();
    }

    if (hasPermission) {
      notifyInternal(notification);
    }
  }

  bool get hasPermission;

  Future<bool> requestPermission();

  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  static Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(linux: initializationSettingsLinux);

    flutterLocalNotificationsPlugin?.initialize(initializationSettings,
        onDidReceiveBackgroundNotificationResponse:
            backgroundNotificationResponse,
        onDidReceiveNotificationResponse: notificationResponse);
  }

  static void backgroundNotificationResponse(NotificationResponse details) {}

  static void notificationResponse(NotificationResponse details) {
    NavigationSignals.openRoom.add(details.payload!);
  }
}
