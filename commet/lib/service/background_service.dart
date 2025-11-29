import 'dart:async';
import 'dart:isolate';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification2.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
}

void handleTask(BackgroundServiceTask task, FlutterBackgroundService service) {
  if (task is BackgroundServiceTaskNotification) {
    Log.i("Handling task: ${task.eventId} ${task.hashCode}");

    FlutterBackgroundService().invoke("on_message_received",
        {"event_id": task.eventId, "room_id": task.roomId});
  }
}

Future<bool> initBackgroundService() async {
  Log.w("Init background service");
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
            autoStart: false,
            autoStartOnBoot: false,
            initialNotificationTitle: "Updating Notifications",
            initialNotificationContent: "Updating Notifications",
            notificationChannelId: channel.id,
            foregroundServiceNotificationId: id));

    await _service!.startService();

    FlutterBackgroundService().invoke("init");
    Log.i("Invoking background service init");

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
      Log.w(
          "Failed to start background service due to missing implementation. This wont show the banner, ${Isolate.current.debugName}");
    } else {
      Log.w(
          "Failed to start background service!, ${Isolate.current.debugName}");
      await preferences.init();
      await preferences.setLastForegroundServiceRunSucceeded(false);
    }
    return false;
  }
}

ServiceInstance? instance;
void onServiceInit(Map<String, dynamic>? data) async {
  if (!preferences.isInit) {
    await preferences.init();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (instance is AndroidServiceInstance) {
    if (await (instance as AndroidServiceInstance).isForegroundService()) {
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

  if (preferences.useLegacyNotificationHandler) {
    Log.i("Using legacy background notification handler");
    var notificationManager = BackgroundNotificationsManager(instance!);

    instance!.on("on_message_received").listen(notificationManager.onReceived);
    await notificationManager.init();

    await Future.delayed(const Duration(milliseconds: 200));
    notificationManager.flushQueueLoop();
  } else {
    Log.i("Using new background handler");
    var notificationManager = BackgroundNotificationsManager2(instance!);
    instance!.on("on_message_received").listen(notificationManager.onReceived);

    await notificationManager.init();

    await Future.delayed(const Duration(milliseconds: 200));
    notificationManager.flushQueueLoop();
  }

  preferences.setLastForegroundServiceRunSucceeded(true);
  instance?.invoke("ready");
}

@pragma('vm:entry-point')
void onServiceStarted(ServiceInstance service) async {
  Log.prefix = "background-service";
  Log.i("Hello from background service, ${Isolate.current.debugName}");
  isHeadless = true;
  instance = service;

  service.on("init").listen(onServiceInit);
}
