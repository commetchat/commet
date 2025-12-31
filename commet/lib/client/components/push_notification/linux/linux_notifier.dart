import 'dart:async';
import 'dart:convert';
import 'package:commet/client/client.dart';
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
import 'package:flutter_local_notifications_linux/src/model/hint.dart' as notif;
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

  static LinuxFlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static void backgroundNotificationResponse(NotificationResponse details) {}

  static const callAccept = "call.accept";
  static const callDecline = "call.decline";
  static const openRoom = "room.open";

  static int notificationId = 0;

  late LinuxServerCapabilities capabilities;

  static void notificationResponse(NotificationResponse details) {
    final payload = jsonDecode(details.payload!) as Map<String, dynamic>;

    var action = details.actionId ?? payload["default_action_id"];

    if (action == "inline-reply") {
      var clientId = payload['client_id'];
      var roomId = payload['room_id'];
      var eventId = payload['event_id'];
      var message = details.input;

      if (clientId == null) return;
      if (roomId == null) return;
      if (eventId == null) return;
      if (message == null) return;

      var client = clientManager!.getClient(clientId);

      if (client == null) return;

      if (message.trim().isNotEmpty) {
        client.getRoom(roomId)?.sendMessage(message: message.trim());
      }
      return;
    }

    if ([callAccept, openRoom].contains(action)) {
      final roomId = payload['room_id']!;
      EventBus.openRoom.add((roomId, null));
      windowManager.show();
      windowManager.focus();
    }

    if ([callAccept, callDecline].contains(action)) {
      final callId = payload['call_id'];
      final clientId = payload['client_id'];
      final session = clientManager?.callManager.currentSessions
          .where(
              (e) => e.sessionId == callId && e.client.identifier == clientId)
          .firstOrNull;

      if (session != null) {
        if (action == callAccept) {
          session.acceptCall(withMicrophone: true);
        }

        if (action == callDecline) {
          session.declineCall();
        }
      }
    }
  }

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = LinuxFlutterLocalNotificationsPlugin();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    await flutterLocalNotificationsPlugin?.initialize(
        initializationSettingsLinux,
        onDidReceiveNotificationResponse: notificationResponse);

    capabilities = await flutterLocalNotificationsPlugin!.getCapabilities();
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

    var image = await ShortcutsManager.createAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.senderName,
        imageProvider: content.senderImage,
        doCircleMask: true,
        shouldZoomOut: false);

    if (content.isDirectMessage == false) {
      var roomImage = await ShortcutsManager.createAvatarImage(
          placeholderColor: room.defaultColor,
          placeholderText: room.displayName,
          imageProvider: content.roomImage,
          doCircleMask: true,
          shouldZoomOut: false);

      image = await ShortcutsManager.combineRoomAndUserImages(roomImage, image);
    }

    var bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final data = bytes!.buffer.asUint8List();

    String notificationBody = content.content;

    var details = LinuxNotificationDetails(
      icon: ByteDataLinuxIcon(LinuxRawIconData(
          data: data,
          width: image.width,
          height: image.height,
          hasAlpha: true,
          channels: 4)),
      defaultActionName: openRoom,
      actions: [
        if (capabilities.otherCapabilities.contains("inline-reply"))
          LinuxNotificationAction(key: "inline-reply", label: "Reply")
      ],
      customHints: [
        notif.LinuxNotificationCustomHint('desktop-entry',
            notif.LinuxHintStringValue("chat.commet.commetapp")),
      ],
      category: LinuxNotificationCategory.imReceived,
    );

    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    var payload = {
      // include default action here as well
      // in some cases it seems `defaultActionName` comes back as null
      // so we can use this as a fallback
      "default_action_id": openRoom,
      "room_id": content.roomId,
      "client_id": content.clientId,
      "event_id": content.eventId,
    };

    flutterLocalNotificationsPlugin?.show(
        notificationId++, title, notificationBody,
        notificationDetails: details, payload: jsonEncode(payload));
  }

  Future<void> displayCallNotification(CallNotificationContent content) async {
    var client = clientManager?.getClient(content.clientId);
    var room = client?.getRoom(content.roomId);

    if (room == null) {
      return;
    }

    var image = await ShortcutsManager.createAvatarImage(
        placeholderColor: room.getColorOfUser(content.senderId),
        placeholderText: content.roomName,
        imageProvider: content.senderImage,
        doCircleMask: true,
        shouldZoomOut: false);

    var bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final data = bytes!.buffer.asUint8List();

    var details = LinuxNotificationDetails(
        icon: ByteDataLinuxIcon(LinuxRawIconData(
            data: data,
            width: image.width,
            height: image.height,
            hasAlpha: true,
            channels: 4)),
        defaultActionName: openRoom,
        category: LinuxNotificationCategory.imReceived,
        timeout: const LinuxNotificationTimeout.expiresNever(),
        urgency: LinuxNotificationUrgency.critical,
        actions: const [
          LinuxNotificationAction(key: callAccept, label: "Accept"),
          LinuxNotificationAction(key: callDecline, label: "Decline"),
        ]);

    var payload = {
      // include default action here as well
      // in some cases it seems `defaultActionName` comes back as null
      // so we can use this as a fallback
      "default_action_id": openRoom,
      "room_id": content.roomId,
      "client_id": content.clientId,
      "call_id": content.callId
    };

    flutterLocalNotificationsPlugin?.show(0, content.title, content.content,
        notificationDetails: details, payload: jsonEncode(payload));
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
