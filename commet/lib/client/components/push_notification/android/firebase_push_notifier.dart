// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/android/android_notifier.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification2.dart';

// Manage these to enable / disable firebase
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:commet/firebase_options.dart';
dynamic Firebase;
dynamic FirebaseMessaging;
dynamic DefaultFirebaseOptions;
// --------

Future<void> onForegroundMessage(dynamic message) async {
  return AndroidNotifier.onForegroundMessage(message.data);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  Log.prefix = "fcm-background";
  Log.i("Got background message: ${message.data}");
  isHeadless = true;

  final data = message.data;

  Log.i("Client Manager: $clientManager");

  await preferences.init();

  try {
    var notificationManager = BackgroundNotificationsManager2(null);

    await notificationManager.init();

    if (!data.containsKey("room_id") || !data.containsKey("event_id")) {
      if (preferences.developerMode.value) {
        // ignore {"prio": "high"} notifications
        if (data.length == 1 && data.containsKey("prio")) {
          return;
        }

        NotificationManager.notify(ErrorNotificationContent(
          title: "Unknown Notification Data",
          content: jsonEncode(data),
        ));
      }

      return;
    }

    notificationManager.handleMessage(data);
  } catch (e, s) {
    Log.e("An error occured while processing unified push background message");
    Log.onError(e, s);
    NotificationManager.notify(ErrorNotificationContent(
        title: "An error occurred while processing notifications",
        content: "${e} \n\n ${s}"));
  }
}

class FirebasePushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  bool get needsToken => true;

  FirebasePushNotifier() {
    notifier = AndroidNotifier();
  }

  @override
  bool get enabled => true;

  String? token;

  @override
  Future<void> init() async {
    Log.i("Initializing firebase push notifier");
    await notifier.init();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    Log.i("Initialized App");
    FirebaseMessaging.instance.onTokenRefresh.listen((event) {
      token = event;
      Log.i("Got new token: $token");
      preferences.fcmKey.set(event);
      preferences.setPushGateway("push.commet.chat");
    });

    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(onForegroundMessage);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  @override
  Future<String?> getToken() async {
    return preferences.fcmKey.value;
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return {"type": "fcm"};
  }

  @override
  Future<void> clearNotifications(Room room) {
    return notifier.clearNotifications(room);
  }
}
