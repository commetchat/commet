import 'dart:ui';

import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidNotifier implements Notifier {
  @override
  bool hasPermission = false;

  @override
  bool get needsToken => false;

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  Map<String, List<Message>> previousMessages = {};

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const settings =
        AndroidInitializationSettings("app_icon_transparent_cropped");
    const initSettings = InitializationSettings(android: settings);

    await flutterLocalNotificationsPlugin?.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
        onDidReceiveNotificationResponse: onResponse);

    if (!isHeadless) {
      checkPermission();
    }
  }

  Future<void> checkPermission() async {
    var android = flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!;

    hasPermission = await android.requestNotificationsPermission() ?? false;
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
      flutterLocalNotificationsPlugin!.getActiveNotifications(),
      shortcutsManager.createShortcutForRoom(room),
    ]);

    Uint8List? userAvatarBytes = result[0];
    Uint8List? roomAvatarBytes = result[1];
    List<ActiveNotification> activeNotifications = result[2];

    var person = Person(
        name: content.senderName,
        important: true,
        bot: false,
        icon: userAvatarBytes != null
            ? ByteArrayAndroidIcon(userAvatarBytes)
            : null);

    var message = Message(
      content.content,
      DateTime.now(),
      person,
    );
    var keys = previousMessages.keys.toList();
    for (var key in keys) {
      if (!activeNotifications.any((element) => element.groupKey == key)) {
        previousMessages.remove(key);
      }
    }

    if (!previousMessages.containsKey(content.roomId)) {
      previousMessages[content.roomId] = List.empty(growable: true);
    }

    previousMessages[content.roomId]!.add(message);

    int id = 0;
    for (var active in activeNotifications) {
      if (active.groupKey == content.roomId) {
        id = active.id!;
        break;
      }

      if (active.id == id && active.groupKey != content.roomId) {
        id += 1;
      }
    }

    var style = MessagingStyleInformation(person,
        conversationTitle: content.isDirectMessage ? content.roomName : null,
        groupConversation: !content.isDirectMessage,
        messages: previousMessages[content.roomId]!);

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
        bubbleActivity: "chat.commet.commetapp.BubbleActivity",
        bubbleExtra:
            OpenRoomURI(roomId: content.roomId, clientId: content.clientId)
                .toString(),
        color: const Color.fromARGB(0xff, 0x53, 0x4c, 0xdd));

    await flutterLocalNotificationsPlugin?.show(
        id, null, content.content, NotificationDetails(android: details));
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

  static void onBackgroundResponse(NotificationResponse details) {
    if (kDebugMode) {
      print("Got a background notification response: $details");
    }
  }

  static void onResponse(NotificationResponse details) {
    if (kDebugMode) {
      print("Got a notification response: $details");
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
}
