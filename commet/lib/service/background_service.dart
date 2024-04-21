import 'dart:async';
import 'dart:ui';

import 'package:commet/debug/log.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  "background_service",
  "Background Updates",
  description: 'Manages tasks in the background.',
  importance: Importance.low,
);

FlutterBackgroundService? _service;

Future<void> doBackgroundServiceTask(BackgroundServiceTask task) async {
  if (_service == null || await _service!.isRunning() == false) {
    await initBackgroundService();
  }

  if (task is BackgroundServiceTaskNotification) {
    _service!.invoke("on_message_received",
        {"event_id": task.eventId, "room_id": task.roomId});
  }
}

Future<bool> initBackgroundService() async {
  _service = FlutterBackgroundService();

  var id = 888;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  try {
    _service!.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
            onStart: onServiceStarted,
            isForegroundMode: true,
            initialNotificationTitle: "Updating Notifications",
            initialNotificationContent: "Updating Notifications",
            notificationChannelId: channel.id,
            foregroundServiceNotificationId: id));

    await _service!.startService();
    return true;
  } catch (_) {
    Log.d("Failed to start background service!");
    return false;
  }
}

@pragma('vm:entry-point')
void onServiceStarted(ServiceInstance service) async {
  Log.i("Service started bitches");

  var notificationManager = BackgroundNotificationsManager(service);
  service.on("on_message_received").listen(notificationManager.onReceived);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      flutterLocalNotificationsPlugin.show(
        888,
        "Updating Notifications",
        null,
        NotificationDetails(
          android: AndroidNotificationDetails(channel.id, channel.name,
              category: AndroidNotificationCategory.service,
              icon: "notification_icon",
              ongoing: true,
              showProgress: true,
              silent: true,
              maxProgress: 100,
              indeterminate: true),
        ),
      );
    }
  }
}
