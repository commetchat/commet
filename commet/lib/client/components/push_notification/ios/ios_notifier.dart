import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/event_bus.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  Log.i("in notificationTapBackground");
  Log.i("Got $notificationResponse");
  IOSNotifier.onResponse(notificationResponse);
  // handle action
}

@pragma('vm:entry-point')
void handlerPushNotificationData({required BuildContext context}) async {
  Log.i("in handlerPushNotificationData()");
  IOSNotifier._channel.setMethodCallHandler((call) async {
    Log.i("in setMethodCallHandler() with call $call");
    if (call.method == "onPushNotification()") {
      Log.i("in onPushNotification");
      final roomId = call.arguments.roomId as String?;
      final eventId = call.arguments.eventId as String?;
      Log.i("roomID $roomId and eventID $eventId");

      if (eventId == null || roomId == null) {
        return;
      }

      var client = clientManager!.clients
          .firstWhere((element) => element.hasRoom(roomId));
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
    } else if (call.method == "didRegister") {
      Log.i("in didRegister()");
      final deviceToken = call.arguments as String;
      Log.i("Received token $deviceToken");
    } else if (call.method == "onBackgroundNotification") {
      Log.i("in onBackgroundNotification()");
      final roomId = call.arguments.roomId as String?;
      final eventId = call.arguments.eventId as String?;
      Log.i("roomID $roomId and eventID $eventId");

      if (eventId == null || roomId == null) {
        return;
      }

      var client = clientManager!.clients
          .firstWhere((element) => element.hasRoom(roomId));
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
  });
}


class IOSNotifier implements Notifier {
  static const String _channelName = "PushNotificationChannel";
  static const MethodChannel _channel = MethodChannel(_channelName);

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  bool hasPermission = false;

  @override
  bool get needsToken => true;

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    Log.i("in init()");
    preferences.setPushGateway("sygnal.spacebinoculars.matrix.town");
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await requestPermission().then((value) async {
      Log.i("Got permission, registering");
      await registerDevice().then((_) async {
        Log.i("Registered");
      });
    });
    const DarwinInitializationSettings settings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(iOS: settings);
    await flutterLocalNotificationsPlugin?.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        onDidReceiveNotificationResponse: onResponse);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    Log.i("in notify()");
    Log.i("Notification: $notification");
    switch (notification.runtimeType) {
      case MessageNotificationContent:
        return displayMessageNotification(
            notification as MessageNotificationContent);
      default:
    }
  }

  Future<void> displayMessageNotification(
      MessageNotificationContent content) async {
    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);
    
    Log.i("in displayMessage() with client $client and room $room");

    if (room == null) {
      return;
    }

    if (flutterLocalNotificationsPlugin == null) {
      Log.i(
          "Flutter local notifications plugin was null. Something went wrong");
      return;
    }

    if (shortcutsManager.loading != null) {
      await shortcutsManager.loading;
    }

    await Future.wait([
      shortcutsManager.createShortcutForRoom(room),
    ]);

    var id = room.identifier.hashCode;

    var payload =
        OpenRoomURI(roomId: content.roomId, clientId: content.clientId)
            .toString();

    await flutterLocalNotificationsPlugin?.show(
        id, null, content.content, const NotificationDetails(),
        payload: payload);
  }

  static Future<void> requestPushNotificationPermission() async {
    Log.i("in requestPushNotificationPermission()");
    try {
      await _channel.invokeMethod("requestNotificationPermissions");
      Log.i("Got Permission");
    } on PlatformException catch (e) {
      Log.e("Failed to get permission with message $e.message");
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  @override
  Future<bool> requestPermission() async {
    Log.i("in requestPermission()");
    try {
      await IOSNotifier.requestPushNotificationPermission();
      return true;
    } on PlatformException catch (e) {
      Log.e("Error Getting Permission: $e.message");
      return false;
    }
  }

  static Future<void> registerDevice() async {
    Log.i("in registerDevice()");
    try {
      await _channel.invokeMethod("registerForPushNotifications");
      Log.i("Registered");
    } on PlatformException {
      return;
    }
  }

  static void onResponse(NotificationResponse details) {
    Log.i("in onResponse()");
    Log.i("Got a notification response: $details");

    if (details.payload == null) return;
    
    Log.i("Payload is $details.payload");

    var uri = CustomURI.parse(details.payload!);

    if (details.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      if (uri is OpenRoomURI) {
        EventBus.openRoom.add((uri.roomId, uri.clientId));
      }
    }
  }
  
  static Future<String?> retriveDeviceToken() async {
    Log.i("in retrieveDeviceToken()");
    try {
      String? token = await _channel.invokeMethod<String>("retrieveDeviceToken");
      return token;
    } on PlatformException catch (e) {
      Log.e("Error on token retrieval: $e.message");
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  @override
  Future<String?> getToken() async {
    Log.i("in getToken()");
    try {
      String? token = await IOSNotifier.retriveDeviceToken();
      return token;
    } on PlatformException {
      return null;
    }
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    Log.i("in extraRegistrationData()");
    var extraData = {
      "default_payload": {
        "aps": {
          "mutable-content": 1,
          "content-available": 1,
          "alert": {"loc-key": "SINGLE_UNREAD", "loc-args": []}
        }
      },
    };
    return extraData;
  }

  @override
  Future<void> clearNotifications(Room room) async {
    return;
  }
}
