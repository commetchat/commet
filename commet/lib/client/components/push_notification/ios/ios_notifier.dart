import 'dart:ui';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void onBackgroundResponse(NotificationResponse details) {
  Log.i("Got a background notification response: $details");
}

class IOSNotifier implements Notifier {
  @override
  bool hasPermission = false;

  @override
  bool get needsToken => false;

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final DarwinInitializationSettings settings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'plainCategory',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'id_1',
              'Action 1',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        )
      ],
    );

    final initSettings = InitializationSettings(iOS: settings);

    await flutterLocalNotificationsPlugin?.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
        onDidReceiveNotificationResponse: onResponse);

    if (!isHeadless) {
      checkPermission();
    }
  }

  Future<void> checkPermission() async {
    var ios = flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()!;
    hasPermission =
        await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
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

    const DarwinNotificationDetails details =
        DarwinNotificationDetails(categoryIdentifier: 'plainCategory');

    const NotificationDetails notificationDetails =
        NotificationDetails(iOS: details);
    await flutterLocalNotificationsPlugin?.show(
        id, null, content.content, notificationDetails,
        payload: payload);
  }

  Future<Uint8List?> getImageBytes(ImageProvider? provider) async {
    if (provider != null) {
      var data = await ImageUtils.imageProviderToImage(provider);
      var bytes = await data.toByteData(format: ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    }
    return null;
  }

  @override
  Future<bool> requestPermission() async {
    return true;
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
    return null;
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<void> clearNotifications(Room room) async {
    var notifications =
        await flutterLocalNotificationsPlugin?.getActiveNotifications();

    if (notifications == null) return;

    for (var noti in notifications) {
      if (noti.groupKey == room.identifier) {
        flutterLocalNotificationsPlugin?.cancel(noti.id!);
      }
    }
  }
}
