// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/android/android_notifier.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification.dart';

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
  doBackgroundServiceTask(BackgroundServiceTaskNotification(
      message.data["room_id"], message.data["event_id"]));
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
      preferences.setFcmKey(event);
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
    return preferences.fcmKey;
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
