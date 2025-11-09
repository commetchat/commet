import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
import 'package:commet/service/background_service.dart';
import 'package:commet/service/background_service_notifications/background_service_task_notification.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';

@pragma('vm:entry-point')
void unifiedPushEntry() async {}

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

  String? _distributor;

  String? get distributor => _distributor;

  String? get endpoint => preferences.unifiedPushEndpoint;

  @override
  bool get enabled => preferences.unifiedPushEnabled == true;

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  Future<void> init() async {
    //if (isInit) return;
    if (preferences.unifiedPushEnabled != true) return;

    await notifier.init();

    Log.i("Initializing unified push");
    UnifiedPush.initialize(onMessage: onMessage, onNewEndpoint: onNewEndpoint);

    var distributor = await UnifiedPush.getDistributor();
    _distributor = distributor;

    isInit = true;
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

  void onNewEndpoint(String endpoint, String instance) async {
    await preferences.setUnifiedPushEndpoint(endpoint);
    await PushNotificationComponent.updateAllPushers();
    onEndpointChanged.add(endpoint);
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
        roomId: room.identifier,
        clientId: client.identifier,
        senderImage: user.avatar,
        roomImage: await room.getShortcutImage(),
        isDirectMessage: isDirectMessage));
  }

  Future<void> onBackgroundMessage(Map<String, dynamic> message) async {
    doBackgroundServiceTask(BackgroundServiceTaskNotification(
        message["room_id"], message["event_id"]));
  }

  void onMessage(Uint8List message, String instance) async {
    var data = utf8.decode(message);
    var json = jsonDecode(data) as Map<String, dynamic>;

    var notifData = json['notification'] as Map<String, dynamic>;
    Log.i("Received message from unified push: $json");

    var eventId = notifData['event_id'] as String;

    // Workaround for notifications being displayed twice sometimes. Not sure where its coming from...
    if (notifiedEvents.contains(eventId)) {
      return;
    }
    notifiedEvents.add(eventId);

    switch (WidgetsBinding.instance.lifecycleState) {
      case null:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        onBackgroundMessage(notifData);
        break;
      case AppLifecycleState.resumed:
        onForegroundMessage(notifData);
    }

    Log.i("${WidgetsBinding.instance.lifecycleState}");
  }

  void onRegistrationFailed(String instance) {}

  void onUnregistered(String instance) {}

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

  @override
  Future<String?> convertFormattedContent(
      String formattedContent, String format, Room room) async {
    return null;
  }
}
