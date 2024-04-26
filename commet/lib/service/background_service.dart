import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  "background_service",
  "Background Updates",
  description: 'Manages tasks in the background.',
  importance: Importance.low,
);

FlutterBackgroundService? _service;
bool isReady = false;

List<BackgroundServiceTask> _taskQueue = List.empty(growable: true);

Future<void> doBackgroundServiceTask(BackgroundServiceTask task) async {
  Log.i("Service: $_service");
  bool isRunning = false;
  if (_service != null) {
    isRunning = await _service!.isRunning();
  }

  Log.i("Running: $isRunning");
  if (isRunning == false) {
    _taskQueue.add(task);
    Log.i("Creating new service");
    await initBackgroundService();
  } else {
    Log.i("Service already existed, reusing");
    handleTask(task, _service!);
  }

  // if (_service == null || (await _service!.isRunning() == false)) {
  //   Log.i("Could not start background service task!");
  //   return;
  // }
}

void handleTask(BackgroundServiceTask task, FlutterBackgroundService service) {
  if (task is BackgroundServiceTaskNotification) {
    Log.i("Handling task: ${task.eventId} ${task.hashCode}");
    FlutterBackgroundService().invoke("on_message_received",
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

    _service!.on("ready").listen((event) {
      var num = _taskQueue.length;

      for (var i = 0; i < num; i++) {
        var task = _taskQueue[0];
        _taskQueue.removeAt(0);

        handleTask(task, _service!);
      }
    });

    return true;
  } catch (exception) {
    if (exception is MissingPluginException) {
      Log.d(
          "Failed to start background service due to missing implementation. This wont show the banner, ${Isolate.current.debugName}");
    } else {
      Log.d(
          "Failed to start background service!, ${Isolate.current.debugName}");
      await preferences.init();
      await preferences.setLastForegroundServiceRunSucceeded(false);
    }
    return false;
  }
}

@pragma('vm:entry-point')
void onServiceStarted(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  Log.i("Hello from background service, ${Isolate.current.debugName}");
  if (!preferences.isInit) {
    await preferences.init();
  }

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
              icon: "ic_bg_service_small",
              ongoing: true,
              showProgress: true,
              silent: true,
              maxProgress: 100,
              indeterminate: true),
        ),
      );
    }
  }

  preferences.setLastForegroundServiceRunSucceeded(true);

  var notificationManager = BackgroundNotificationsManager(service);
  await notificationManager.init();

  service.on("on_message_received").listen(notificationManager.onReceived);

  service.invoke("ready");

  await Future.delayed(const Duration(milliseconds: 200));
  notificationManager.flushQueueLoop();
}
