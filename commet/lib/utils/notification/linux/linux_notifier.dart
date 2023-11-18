import 'dart:async';

import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;
import '../../event_bus.dart';

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

  static void notificationResponse(NotificationResponse details) {
    EventBus.openRoom.add((details.payload!, null));
    windowManager.show();
    windowManager.focus();
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
    switch (notification.runtimeType) {
      case MessageNotificationContent:
        return displayMessageNotification(
            notification as MessageNotificationContent);
      default:
    }
  }

  Future<void> displayMessageNotification(
      MessageNotificationContent content) async {
    LinuxNotificationIcon? icon;

    if (content.senderImage != null) {
      var image = await determineImage(content.senderImage!);
      var bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))
          ?.buffer
          .asUint8List();

      icon = ByteDataLinuxIcon(LinuxRawIconData(
          data: bytes!,
          width: image.width,
          height: image.height,
          bitsPerSample: 8,
          channels: 4,
          hasAlpha: true));
    }

    var details = LinuxNotificationDetails(
      icon: icon,
      defaultActionName: "NAVIGATE_ROOM",
      category: LinuxNotificationCategory.imReceived,
    );

    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    flutterLocalNotificationsPlugin?.show(
        0, title, content.content, NotificationDetails(linux: details),
        payload: content.roomId);
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
}
