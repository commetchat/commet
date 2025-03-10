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

class IOSNotifier implements Notifier {
  static const String _channelName = "PushNotificationChannel";
  static const MethodChannel _channel = MethodChannel(_channelName);

  @override
  bool hasPermission = false;

  @override
  bool get needsToken => true;

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    await requestPermission().then((value) async {
      await registerDevice();
    });
  }

  @override
  Future<void> notify(NotificationContent notification) async {
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

    if (room == null) {
      return;
    }

    if (shortcutsManager.loading != null) {
      await shortcutsManager.loading;
    }

    await Future.wait([
      shortcutsManager.createShortcutForRoom(room),
    ]);

    EventBus.openRoom.add((content.roomId, content.clientId));
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _channel.invokeMethod("requestNotificationPermissions");
      return true;
    } on PlatformException catch (e) {
      Log.e("Error Getting Permission: $e.message");
      return false;
    }
  }

  static Future<void> registerDevice() async {
    try {
      await _channel.invokeMethod("registerForPushNotifications");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  static void onResponse(NotificationResponse details) {
    Log.i("Got a notification response: $details");

    if (details.payload == null) return;

    var uri = CustomURI.parse(details.payload!);

    if (details.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      if (uri is OpenRoomURI) {
        EventBus.openRoom.add((uri.roomId, uri.clientId));
      }
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      String? token =
          await _channel.invokeMethod<String>("retrieveDeviceToken");
      Log.i("APNS Device Token is $token");
      return token;
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    var extraData = {
      "default_payload": {
        "aps": {
          "alert": {
            "loc-args": [],
            "loc-key": "Notification",
          },
          "mutable-content": 1,
          "content_available": 1,
        },
      },
    };
    return extraData;
  }

  static handlerPushNotificationData({required BuildContext context}) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onPushNotification") {
        final roomId = call.arguments.roomId as String?;
        final eventId = call.arguments.eventId as String?;

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

  @override
  Future<void> clearNotifications(Room room) async {
    return;
  }
}

//@pragma('vm:entry-point')
//void onBackgroundResponse(NotificationResponse details) {
//  Log.i("Got a background notification response: $details");
//}
//
//Future<void> onNotification(dynamic message) async {
//  String? eventId = message.data['event_id'];
//  String? roomId = message.data['room_id'];
//  if (eventId == null || roomId == null) {
//    return;
//  }
//
//  Log.i("Got firebase message: $message");
//
//  var client =
//      clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));
//  var room = client.getRoom(roomId);
//  var event = await room!.getEvent(eventId);
//
//  var user = await room.fetchMember(event!.senderId);
//
//  Log.i("Dispatching notification");
//
//  bool isDirectMessage = client
//          .getComponent<DirectMessagesComponent>()
//          ?.isRoomDirectMessage(room) ??
//      false;
//
//  NotificationManager.notify(MessageNotificationContent(
//      senderName: user.displayName,
//      senderId: user.identifier,
//      roomName: room.displayName,
//      content: event.plainTextBody,
//      eventId: eventId,
//      roomId: room.identifier,
//      clientId: client.identifier,
//      senderImage: user.avatar,
//      roomImage: await room.getShortcutImage(),
//      isDirectMessage: isDirectMessage));
//}
//
//class IOSNotifier implements Notifier {
//  @override
//  bool get hasPermission => true;
//
//  @override
//  bool get needsToken => false;
//
//  @override
//  bool get enabled => true;
//
//  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
//
//  String? token;
//
//  @override
//  Future<void> init() async {
//    Log.i("Initializing ios push notifier");
//
//    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//    final DarwinInitializationSettings settings = DarwinInitializationSettings(
//      requestSoundPermission: false,
//      requestBadgePermission: false,
//      requestAlertPermission: false,
//      notificationCategories: [
//        DarwinNotificationCategory(
//          'plainCategory',
//          actions: <DarwinNotificationAction>[
//            DarwinNotificationAction.plain(
//              'id_1',
//              'Action 1',
//             options: <DarwinNotificationActionOption>{
//               DarwinNotificationActionOption.foreground,
//             },
//            ),
//          ],
//          options: <DarwinNotificationCategoryOption>{
//            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
//          },
//        )
//      ],
//    );
//
//    final initSettings = InitializationSettings(iOS: settings);
//
//    await flutterLocalNotificationsPlugin?.initialize(initSettings,
//        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
//        onDidReceiveNotificationResponse: onResponse);
//
//    await NativePush.instance.initialize(
//      firebaseOptions: {
//        'apiKey': DefaultFirebaseOptions.currentPlatform.apiKey,
//        'projectId': DefaultFirebaseOptions.currentPlatform.projectId,
//        'messagingSenderId': DefaultFirebaseOptions.currentPlatform.messagingSenderId,
//        'applicationId': DefaultFirebaseOptions.currentPlatform.appId,
//      },
//      useDefaultNotificationChannel: true,
//    );
//
//    await NativePush.instance.registerForRemoteNotification(
//      options: [
//        NotificationOption.alert,
//        NotificationOption.sound,
//        NotificationOption.badge
//      ],
//    );
//
//    NativePush.instance.notificationStream.listen((notification) {
//      onNotification(notification);
//      Log.i('Received notification: $notification');
//    });
//  }
//
//  static void onResponse(NotificationResponse details) {
//    Log.i("Got a notification response: $details");
//
//    if (details.payload == null) return;
//
//    var uri = CustomURI.parse(details.payload!);
//
//    if (details.notificationResponseType ==
//        NotificationResponseType.selectedNotification) {
//      if (uri is OpenRoomURI) {
//        EventBus.openRoom.add((uri.roomId, uri.clientId));
//      }
//    }
//  }
//
//  @override
//  Future<void> notify(NotificationContent notification) async {
//   Log.i("Notifying $notification");
//   switch (notification.runtimeType) {
//     case MessageNotificationContent:
//       return displayMessageNotification(
//           notification as MessageNotificationContent);
//     default:
//   }
//  }
//
//  Future<void> displayMessageNotification(
//      MessageNotificationContent content) async {
//    var client = clientManager?.getClient(content.clientId);
//    var room = client?.getRoom(content.roomId);
//
//    Log.i("Displaying Message $content");
//
//    if (room == null) {
//      return;
//    }
//
//    if (shortcutsManager.loading != null) {
//      await shortcutsManager.loading;
//    }
//
//    await Future.wait([
//      shortcutsManager.createShortcutForRoom(room),
//    ]);
//
//    var id = room.identifier.hashCode;
//
//    var payload =
//        OpenRoomURI(roomId: content.roomId, clientId: content.clientId)
//            .toString();
//
//    const DarwinNotificationDetails details =
//        DarwinNotificationDetails(
//          interruptionLevel: InterruptionLevel.active,
//          categoryIdentifier: 'plainCategory'
//        );
//
//    const NotificationDetails notificationDetails =
//        NotificationDetails(iOS: details);
//    await flutterLocalNotificationsPlugin?.show(
//        id, null, content.content, notificationDetails,
//        payload: payload);
//  }
//
//  @override
//  Future<String?> getToken() async {
//    final (service, token) = await NativePush.instance.notificationToken;
//    return token;
//  }
//
//  @override
//  Future<bool> requestPermission() async {
//    return true;
//  }
//
//  @override
//  Map<String, dynamic>? extraRegistrationData() {
//    var extraData = {
//      "type": "fcm",
//      "default_payload": {
//        "aps": {
//          "alert": {
//            "loc-args": [],
//            "loc-key": "Notification",
//          },
//          "mutable-content": 1,
//          "content_available": 1,
//        },
//      },
//      "data_message": "ios",
////      "content_available": 1,
////      "apns": {"payload": {"aps": {"mutable-content": 1, "content-available": 1}}},
//    };
//    return extraData;
//  }
//
//  @override
//  Future<void> clearNotifications(Room room) async {
//    var notifications =
//        await flutterLocalNotificationsPlugin?.getActiveNotifications();
//
//    if (notifications == null) return;
//
//    for (var noti in notifications) {
//      if (noti.groupKey == room.identifier) {
//        flutterLocalNotificationsPlugin?.cancel(noti.id!);
//      }
//    }
//  }
//}

//@pragma('vm:entry-point')
//void onBackgroundResponse(NotificationResponse details) {
// Log.i("Got a background notification response: $details");
//}
//
//class IOSNotifier implements Notifier {
// @override
// bool hasPermission = false;
//
// @override
// bool get needsToken => true;
//
// FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
//
// @override
// bool get enabled => true;
//
// @override
// Future<void> init() async {
//   flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   final DarwinInitializationSettings settings = DarwinInitializationSettings(
//     notificationCategories: [
//       DarwinNotificationCategory(
//         'plainCategory',
//         actions: <DarwinNotificationAction>[
//           DarwinNotificationAction.plain(
//             'id_1',
//             'Action 1',
//            options: <DarwinNotificationActionOption>{
//              DarwinNotificationActionOption.foreground,
//            },
//           ),
//         ],
//         options: <DarwinNotificationCategoryOption>{
//           DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
//         },
//       )
//     ],
//   );
//
//   final initSettings = InitializationSettings(iOS: settings);
//
//   await flutterLocalNotificationsPlugin?.initialize(initSettings,
//       onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
//       onDidReceiveNotificationResponse: onResponse);
//
//   if (!isHeadless) {
//     checkPermission();
//   }
// }
//
// Future<void> checkPermission() async {
//   var ios = flutterLocalNotificationsPlugin!
//       .resolvePlatformSpecificImplementation<
//           IOSFlutterLocalNotificationsPlugin>()!;
//   hasPermission =
//       await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
// }
//
// @override
// Future<void> notify(NotificationContent notification) async {
//   switch (notification.runtimeType) {
//     case MessageNotificationContent:
//       return displayMessageNotification(
//           notification as MessageNotificationContent);
//     default:
//   }
// }
//
// Future<void> displayMessageNotification(
//     MessageNotificationContent content) async {
//   var client = clientManager?.getClient(content.clientId);
//   var room = client?.getRoom(content.roomId);
//
//   if (room == null) {
//     return;
//   }
//
//   if (flutterLocalNotificationsPlugin == null) {
//     Log.i(
//         "Flutter local notifications plugin was null. Something went wrong");
//     return;
//   }
//
//   if (shortcutsManager.loading != null) {
//     await shortcutsManager.loading;
//   }
//
//   await Future.wait([
//     shortcutsManager.createShortcutForRoom(room),
//   ]);
//
//   var id = room.identifier.hashCode;
//
//   var payload =
//       OpenRoomURI(roomId: content.roomId, clientId: content.clientId)
//           .toString();
//
//   const DarwinNotificationDetails details =
//       DarwinNotificationDetails(
//         interruptionLevel: InterruptionLevel.active,
//         categoryIdentifier: 'plainCategory'
//       );
//
//   const NotificationDetails notificationDetails =
//       NotificationDetails(iOS: details);
//   await flutterLocalNotificationsPlugin?.show(
//       id, null, content.content, notificationDetails,
//       payload: payload);
// }
//
// @override
// Future<bool> requestPermission() async {
//   var ios = flutterLocalNotificationsPlugin!
//       .resolvePlatformSpecificImplementation<
//           IOSFlutterLocalNotificationsPlugin>()!;
//   hasPermission =
//       await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
//   return hasPermission;
// }
//
// static void onResponse(NotificationResponse details) {
//   Log.i("Got a notification response: $details");
//
//   if (details.payload == null) return;
//
//   var uri = CustomURI.parse(details.payload!);
//
//   if (details.notificationResponseType ==
//       NotificationResponseType.selectedNotification) {
//     if (uri is OpenRoomURI) {
//       EventBus.openRoom.add((uri.roomId, uri.clientId));
//     }
//   }
// }
//
// @override
// Future<String?> getToken() async {
//   var firebaseInstance = FirebaseMessaging.instance;
//   var apns = await firebaseInstance.getAPNSToken();
//   Log.i('apns $apns ');
//   var firebase = await firebaseInstance.getToken();
//   Log.i('token $firebase');
//   return firebase;
// }
//
// @override
// Map<String, dynamic>? extraRegistrationData() {
//   var extraData = {
//     "type": "fcm",
//     "default_payload": {
//       "aps": {
//         "alert": {
//           "loc-args": [],
//           "loc-key": "Notification",
//         },
//         "mutable-content": 1,
//         "content_available": true,
//       },
//     },
//     "data_message": "ios",
//     "content_available": true,
//     "apns": {"payload": {"aps": {"mutable-content": 1, "content-available": true}}},
//   };
//   return extraData;
// }
//
// @override
// Future<void> clearNotifications(Room room) async {
//   var notifications =
//       await flutterLocalNotificationsPlugin?.getActiveNotifications();
//
//   if (notifications == null) return;
//
//   for (var noti in notifications) {
//     if (noti.groupKey == room.identifier) {
//       flutterLocalNotificationsPlugin?.cancel(noti.id!);
//     }
//   }
// }
//}
