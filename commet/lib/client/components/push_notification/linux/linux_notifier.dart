import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;

class LinuxNotifier implements Notifier {
  @override
  bool get hasPermission => true;

  static NotificationsClient client = NotificationsClient();

  @override
  bool get enabled => true;

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static void backgroundNotificationResponse(NotificationResponse details) {}

  static const callAccept = "call.accept";
  static const callDecline = "call.decline";
  static const openRoom = "room.open";

  static void notificationResponse(NotificationResponse details) {
    final payload = jsonDecode(details.payload!) as Map<String, dynamic>;

    if ([callAccept, openRoom].contains(details.actionId)) {
      final roomId = payload['room_id']!;
      EventBus.openRoom.add((roomId, null));
      windowManager.show();
      windowManager.focus();
    }

    if ([callAccept, callDecline].contains(details.actionId)) {
      final callId = payload['call_id'];
      final clientId = payload['client_id'];
      final session = clientManager?.callManager.currentSessions
          .where(
              (e) => e.sessionId == callId && e.client.identifier == clientId)
          .firstOrNull;

      if (session != null) {
        if (details.actionId == callAccept) {
          session.acceptCall(withMicrophone: true);
        }

        if (details.actionId == callDecline) {
          session.declineCall();
        }
      }
    }
  }

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(linux: initializationSettingsLinux);

    flutterLocalNotificationsPlugin?.initialize(initializationSettings,
        onDidReceiveBackgroundNotificationResponse:
            backgroundNotificationResponse,
        onDidReceiveNotificationResponse: notificationResponse);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    switch (notification) {
      case MessageNotificationContent _:
        return displayMessageNotification(notification);
      case CallNotificationContent _:
        return displayCallNotification(notification);
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

    var avatar = await ShortcutsManager.getCachedAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.senderName,
        identifier: content.senderId,
        shouldZoomOut: false,
        imageProvider: content.senderImage);

    var details = LinuxNotificationDetails(
      icon: avatar == null ? null : FilePathLinuxIcon(avatar.toFilePath()),
      defaultActionName: openRoom,
      category: LinuxNotificationCategory.imReceived,
    );

    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    var payload = {
      "room_id": content.roomId,
    };

    flutterLocalNotificationsPlugin?.show(
        0, title, content.content, NotificationDetails(linux: details),
        payload: jsonEncode(payload));
  }

  Future<void> displayCallNotification(CallNotificationContent content) async {
    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);

    if (room == null) {
      return;
    }

    var avatar = await ShortcutsManager.getCachedAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.roomName,
        identifier: content.senderId,
        shouldZoomOut: false,
        imageProvider: content.senderImage);

    var details = LinuxNotificationDetails(
        icon: avatar == null ? null : FilePathLinuxIcon(avatar.toFilePath()),
        defaultActionName: openRoom,
        category: LinuxNotificationCategory.imReceived,
        timeout: const LinuxNotificationTimeout.expiresNever(),
        urgency: LinuxNotificationUrgency.critical,
        actions: const [
          LinuxNotificationAction(key: callAccept, label: "Accept"),
          LinuxNotificationAction(key: callDecline, label: "Decline"),
        ]);

    var payload = {
      "room_id": content.roomId,
      "client_id": content.clientId,
      "call_id": content.callId
    };

    flutterLocalNotificationsPlugin?.show(
        0, content.title, content.content, NotificationDetails(linux: details),
        payload: jsonEncode(payload));
  }

  Future<ui.Image> determineImage(ImageProvider provider) async {
    if (provider is LODImageProvider) {
      var data = await provider.loadThumbnail?.call();
      var mem = MemoryImage(data!);
      return await ImageUtils.imageProviderToImage(mem);
    }

    return await ImageUtils.imageProviderToImage(provider);
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  bool get needsToken => false;

  @override
  Future<void> clearNotifications(Room room) async {}
}
