import 'dart:typed_data';
import 'dart:ui';

import 'package:commet/main.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidNotifier implements Notifier {
  @override
  bool get hasPermission => true;

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const settings =
        AndroidInitializationSettings("app_icon_transparent_cropped");
    const initSettings = InitializationSettings(android: settings);

    await flutterLocalNotificationsPlugin?.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
        onDidReceiveNotificationResponse: onResponse);
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

    List<dynamic> result = await Future.wait([
      getImageBytes(content.senderImage),
      getImageBytes(content.roomImage),
      shortcutsManager.createShortcutForRoom(room),
    ]);

    Uint8List? userAvatarBytes = result[0];
    Uint8List? roomAvatarBytes = result[1];

    var person = Person(
        name: content.senderName,
        important: true,
        bot: false,
        icon: userAvatarBytes != null
            ? ByteArrayAndroidIcon(userAvatarBytes)
            : null);

    var style = MessagingStyleInformation(person,
        conversationTitle: content.isDirectMessage ? content.roomName : null,
        groupConversation: !content.isDirectMessage,
        messages: [Message(content.content, DateTime.now(), person)]);

    var details = AndroidNotificationDetails(
        "messages", "Notifies when a message is received",
        importance: Importance.high,
        priority: Priority.high,
        icon: "app_icon_transparent_cropped",
        largeIcon: roomAvatarBytes != null
            ? ByteArrayAndroidBitmap(roomAvatarBytes)
            : null,
        subText: content.roomName,
        groupKey: content.roomId,
        groupAlertBehavior: GroupAlertBehavior.children,
        styleInformation: style,
        shortcutId: content.roomId,
        color: const Color.fromARGB(0xff, 0x53, 0x4c, 0xdd));

    await flutterLocalNotificationsPlugin?.show(
        0, null, content.content, NotificationDetails(android: details));
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

  static void onBackgroundResponse(NotificationResponse details) {}

  static void onResponse(NotificationResponse details) {}
}
