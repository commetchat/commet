import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/matrix_background/matrix_background_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidNotifier implements Notifier {
  @override
  bool hasPermission = false;

  @override
  bool get needsToken => false;

  static const bool bubblesEnabled = true;

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    Log.i("Initializing notifier! is headless: $isHeadless");

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const settings = AndroidInitializationSettings("notification_icon");
    const initSettings = InitializationSettings(android: settings);

    await flutterLocalNotificationsPlugin?.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
        onDidReceiveNotificationResponse: onResponse);

    if (!isHeadless) {
      checkPermission();
    }
  }

  static Future<void> onForegroundMessage(Map<String, dynamic> message) async {
    var roomId = message["room_id"] as String?;
    var eventId = message["event_id"] as String?;
    var counts = message["counts"] as String?;

    if (roomId == null || eventId == null) {
      Log.w("TODO: Handle counts: $counts");
      return;
    }

    var client = clientManager!.clients
        .firstWhereOrNull((element) => element.hasRoom(roomId));

    if (client == null) {
      client = clientManager!.clients.firstWhereOrNull((client) =>
          client
              .getComponent<InvitationComponent>()
              ?.invitations
              .any((i) => i.roomId == roomId) ==
          true);

      for (client in clientManager!.clients) {
        final comp = client.getComponent<InvitationComponent>();

        var invite =
            comp?.invitations.firstWhereOrNull((i) => i.roomId == roomId);

        if (invite != null) {
          var content = GenericRoomInviteNotificationContent(
            content: "You received an invitation to chat!",
            title: "Room Invite",
          );

          await NotificationManager.notify(content);

          return;
        }
      }

      return;
    }

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

  Future<void> checkPermission() async {
    var android = flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!;

    hasPermission = await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    switch (notification) {
      case MessageNotificationContent _:
        return displayMessageNotification(notification);
      case ErrorNotificationContent _:
        return displayErrorNotification(notification);
      case GenericRoomInviteNotificationContent _:
        return displayGenericInviteNotification(notification);
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

    if (room is MatrixBackgroundRoom) {
      await room.init();
    }

    if (flutterLocalNotificationsPlugin == null) {
      Log.i(
          "Flutter local notifications plugin was null. Something went wrong");
      return;
    }

    if (shortcutsManager.loading != null) {
      await shortcutsManager.loading;
    }

    Log.i("Sender name: '${content.senderName}'");
    Log.i("Room Name: '${room.displayName}'");

    Uri? userAvatar = await ShortcutsManager.getCachedAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.senderName,
        imageId: content.senderImageId,
        identifier: content.senderId,
        format: ShortcutIconFormat.png,
        shouldZoomOut: false,
        imageProvider: content.senderImage);

    Uri? roomAvatar = await ShortcutsManager.getCachedAvatarImage(
        placeholderColor: room.defaultColor,
        placeholderText: content.roomName,
        imageId: content.roomImageId,
        format: ShortcutIconFormat.png,
        identifier: room.identifier,
        imageProvider: await room.getShortcutImage());

    await Future.wait([
      shortcutsManager.createShortcutForRoom(room),
    ]);

    var id = room.identifier.hashCode;
    var activeStyleInfo = await AndroidFlutterLocalNotificationsPlugin()
        .getActiveNotificationMessagingStyle(id);

    var person = Person(
        name: content.senderName,
        important: true,
        bot: false,
        key: content.senderId,
        icon: userAvatar == null
            ? null
            : BitmapFilePathAndroidIcon(userAvatar.toFilePath()));

    var message = Message(
      content.content,
      DateTime.now(),
      person,
    );

    var payload =
        OpenRoomURI(roomId: content.roomId, clientId: content.clientId)
            .toString();

    activeStyleInfo?.messages?.add(message);

    var style = activeStyleInfo ??
        MessagingStyleInformation(person,
            conversationTitle:
                content.isDirectMessage ? content.roomName : null,
            groupConversation: !content.isDirectMessage,
            messages: [message]);

    var details = AndroidNotificationDetails("messages", "Message Received",
        importance: Importance.high,
        priority: Priority.high,
        icon: "notification_icon",
        number: style.messages!.length,
        largeIcon: FilePathAndroidBitmap(roomAvatar.toString()),
        subText: content.roomName,
        groupKey: content.roomId,
        groupAlertBehavior: GroupAlertBehavior.all,
        styleInformation: style,
        shortcutId: content.roomId,
        silent: content.priority == NotificationPriority.low,
        ticker: content.content,
        bubble: bubblesEnabled
            ? BubbleMetadata(
                "chat.commet.commetapp.BubbleActivity",
                extra: payload,
                desiredHeight: 600,
              )
            : null,
        color: const Color.fromARGB(0xff, 0x53, 0x4c, 0xdd));

    await flutterLocalNotificationsPlugin?.show(
        id, null, content.content, NotificationDetails(android: details),
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

  static void onBackgroundResponse(NotificationResponse details) {
    Log.i("Got a background notification response: $details");
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

  Future<void> displayErrorNotification(
      ErrorNotificationContent notification) async {
    var details = AndroidNotificationDetails(
      "errors",
      "Error Messages",
      importance: Importance.high,
      priority: Priority.high,
      icon: "notification_icon",
      styleInformation: BigTextStyleInformation(notification.content),
    );

    await flutterLocalNotificationsPlugin?.show(
      Random().nextInt(1000000),
      notification.title,
      notification.content,
      NotificationDetails(android: details),
    );
  }

  Future<void> displayGenericInviteNotification(
      GenericRoomInviteNotificationContent notification) async {
    var details = AndroidNotificationDetails(
      "chat_invites",
      "Chat Invitations",
      importance: Importance.high,
      priority: Priority.high,
      icon: "notification_icon",
    );

    await flutterLocalNotificationsPlugin?.show(
      Random().nextInt(1000000),
      notification.title,
      notification.content,
      NotificationDetails(android: details),
    );
  }
}
