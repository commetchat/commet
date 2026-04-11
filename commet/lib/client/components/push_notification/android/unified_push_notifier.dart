import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/android/android_notifier.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification2.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get needsToken => true;

  List<String> notifiedEvents = List.empty(growable: true);

  bool isInit = false;

  UnifiedPushNotifier() {
    notifier = AndroidNotifier();

    if (preferences.unifiedPushEnabled.value == null) {
      FirstTimeSetup.registerPostLoginSetup(UnifiedPushSetup());
    }
  }

  StreamController<String> onEndpointChanged = StreamController.broadcast();

  String? get endpoint => preferences.unifiedPushEndpoint.value;

  @override
  bool get enabled => preferences.unifiedPushEnabled.value == true;

  @override
  bool get hasPermission => notifier.hasPermission;

  String get instance => isHeadless ? "background_task" : "default";

  @override
  Future<void> init() async {
    if (isInit) return;
    if (preferences.unifiedPushEnabled.value != true) return;

    await notifier.init();

    Log.i("Initializing unified push");
    UnifiedPush.initialize(onMessage: onMessage, onNewEndpoint: onNewEndpoint);

    isInit = true;
  }

  @override
  Future<String?> getToken() async {
    if (preferences.unifiedPushEnabled.value != true) {
      return null;
    }

    return preferences.unifiedPushEndpoint.value;
  }

  @override
  Future<void> notify(NotificationContent notification) {
    return notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  void onNewEndpoint(String endpoint, String instance) async {
    print("Got new endpoint: $instance");
    await preferences.unifiedPushEndpoint.set(endpoint);
    await PushNotificationComponent.updateAllPushers();
    onEndpointChanged.add(endpoint);
  }

  Future<void> onBackgroundMessage(Map<String, dynamic> message) async {
    try {
      var notificationManager = BackgroundNotificationsManager2(null);

      await notificationManager.init();

      if (!message.containsKey("room_id") || !message.containsKey("event_id")) {
        if (preferences.developerMode.value) {
          // ignore {"prio": "high"} notifications
          if (message.length == 1 && message.containsKey("prio")) {
            return;
          }

          NotificationManager.notify(ErrorNotificationContent(
            title: "Unknown Notification Data",
            content: jsonEncode(message),
          ));
        }

        return;
      }

      notificationManager.handleMessage(message);
    } catch (e, s) {
      Log.e(
          "An error occured while processing unified push background message");
      Log.onError(e, s);
      NotificationManager.notify(ErrorNotificationContent(
          title: "An error occurred while processing notifications",
          content: "${e} \n\n ${s}"));
    }
  }

  void onMessage(Uint8List message, String instance) async {
    Log.i("Received unified push message! $instance");
    var data = utf8.decode(message);
    var json = jsonDecode(data) as Map<String, dynamic>;

    var notifData = json['notification'] as Map<String, dynamic>;
    Log.i("Received message from unified push: $json");

    // Workaround for notifications being displayed twice sometimes. Not sure where its coming from...
    if (notifData.containsKey("event_id")) {
      var eventId = notifData['event_id'] as String;

      if (notifiedEvents.contains(eventId)) {
        return;
      }
      notifiedEvents.add(eventId);

      Timer(Duration(seconds: 5), () {
        notifiedEvents.removeWhere((e) => e == eventId);
      });
    }

    if (isHeadless) {
      onBackgroundMessage(notifData);
    } else {
      AndroidNotifier.onForegroundMessage(notifData);
    }

    Log.i("${WidgetsBinding.instance.lifecycleState}");
  }

  void onUnregistered(String instance) {
    Log.i("Unified push unregistered: $instance");
  }

  Future<void> unregister() async {
    await UnifiedPush.unregister();
    await preferences.unifiedPushEnabled.set(false);
    await preferences.unifiedPushEndpoint.set(null);
    await PushNotificationComponent.updateAllPushers();
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<void> clearNotifications(Room room) {
    return notifier.clearNotifications(room);
  }
}
