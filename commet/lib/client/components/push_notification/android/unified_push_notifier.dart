import 'dart:async';
import 'dart:convert';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
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

@pragma('vm:entry-point')
void unifiedPushEntry() async {
  isHeadless = true;
  Log.prefix = "unified-push";
  await WidgetsFlutterBinding.ensureInitialized();
  await preferences.init();
  await UnifiedPushNotifier().init();
}

class UnifiedPushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get needsToken => true;

  List<String> notifiedEvents = List.empty(growable: true);

  bool isInit = false;

  UnifiedPushNotifier() {
    notifier = AndroidNotifier();

    if (preferences.unifiedPushEnabled == null) {
      FirstTimeSetup.registerPostLoginSetup(UnifiedPushSetup());
    }
  }

  StreamController<String> onEndpointChanged = StreamController.broadcast();

  String? get endpoint => preferences.unifiedPushEndpoint;

  @override
  bool get enabled => preferences.unifiedPushEnabled == true;

  @override
  bool get hasPermission => notifier.hasPermission;

  String get instance => isHeadless ? "background_task" : "default";

  @override
  Future<void> init() async {
    if (isInit) return;
    if (preferences.unifiedPushEnabled != true) return;

    await notifier.init();

    Log.i("Initializing unified push");
    var result = await UnifiedPush.initialize(
        onMessage: onMessage,
        onNewEndpoint: onNewEndpoint,
        onUnregistered: onUnregistered,
        onRegistrationFailed: onRegistrationFailed);

    if (!result) {
      await UnifiedPush.register(instance: instance);
    }

    Log.i("Registered unified push ($instance): $result");

    isInit = true;
  }

  void onRegistrationFailed(FailedReason reason, String instance) {
    Log.e("UnifiedPush registration failed: ${instance} - ${reason.name} ");
  }

  @override
  Future<String?> getToken() async {
    if (preferences.unifiedPushEnabled != true) {
      return null;
    }

    return preferences.unifiedPushEndpoint;
  }

  @override
  Future<void> notify(NotificationContent notification) {
    return notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  void onNewEndpoint(PushEndpoint endpoint, String instance) async {
    Log.i("New endpoint ($instance): ${endpoint}");
    await preferences.setUnifiedPushEndpoint(endpoint.url);
    await PushNotificationComponent.updateAllPushers();
    onEndpointChanged.add(endpoint.url);
  }

  Future<void> onForegroundMessage(Map<String, dynamic> message) async {
    var roomId = message['room_id'] as String;
    var eventId = message['event_id'] as String;

    notifiedEvents.add(eventId);

    var client =
        clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));
    var room = client.getRoom(roomId);
    var event = await room!.getEvent(eventId);

    var user = await room.fetchMember(event!.senderId);

    bool isDirectMessage = client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(room) ??
        false;

    NotificationManager.notify(MessageNotificationContent(
        senderName: user.displayName,
        senderId: user.identifier,
        roomName: room.displayName,
        content: event.plainTextBody,
        eventId: eventId,
        senderImageId: user.avatarId,
        roomImageId: room.avatarId,
        roomId: room.identifier,
        clientId: client.identifier,
        senderImage: user.avatar,
        roomImage: await room.getShortcutImage(),
        isDirectMessage: isDirectMessage));
  }

  Future<void> onBackgroundMessage(Map<String, dynamic> message) async {
    try {
      var notificationManager = BackgroundNotificationsManager2(null);

      await notificationManager.init();

      if (!message.containsKey("room_id") || !message.containsKey("event_id")) {
        NotificationManager.notify(ErrorNotificationContent(
          title: "Unknown Notification Data",
          content: jsonEncode(message),
        ));

        return;
      }

      notificationManager.handleMessage(
          {"event_id": message["event_id"], "room_id": message["room_id"]});
    } catch (e, s) {
      Log.e(
          "An error occured while processing unified push background message");
      Log.onError(e, s);
      NotificationManager.notify(ErrorNotificationContent(
          title: "An error occurred while processing notifications",
          content: "${e} \n\n ${s}"));
    }
  }

  void onMessage(PushMessage message, String instance) async {
    Log.i("Received unified push message!");
    var data = utf8.decode(message.content);
    var json = jsonDecode(data) as Map<String, dynamic>;

    var notifData = json['notification'] as Map<String, dynamic>;
    Log.i("Received message from unified push: $json");

    if (commandLineArgs.contains("--unifiedpush-bg")) {
      onBackgroundMessage(notifData);
    } else {
      onForegroundMessage(notifData);
    }

    Log.i("${WidgetsBinding.instance.lifecycleState}");
  }

  void onUnregistered(String instance) {
    Log.i("Unified push unregistered: $instance");
  }

  Future<void> unregister() async {
    await UnifiedPush.unregister();
    await preferences.setUnifiedPushEnabled(false);
    await preferences.setUnifiedPushEndpoint(null);
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
