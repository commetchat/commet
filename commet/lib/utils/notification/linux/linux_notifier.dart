import 'dart:async';

import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;
import '../../../ui/navigation/navigation_signals.dart';
import '../notification_manager.dart';

class LinuxNotifier extends Notifier {
  @override
  bool get hasPermission => true;

  static NotificationsClient client = NotificationsClient();

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static void backgroundNotificationResponse(NotificationResponse details) {}

  static void notificationResponse(NotificationResponse details) {
    NavigationSignals.openRoom.add(details.payload!);
    windowManager.show();
    windowManager.focus();
  }

  static Future<void> init() async {
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
  Future<void> notifyInternal(NotificationContent notification) async {
    LinuxNotificationIcon? icon;

    if (notification.image != null) {
      var image = await determineImage(notification.image!);
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

    flutterLocalNotificationsPlugin?.show(0, notification.title,
        notification.content, NotificationDetails(linux: details),
        payload: notification.sentFrom?.identifier);
  }

  Future<ui.Image> determineImage(ImageProvider provider) async {
    if (provider is LODImageProvider) {
      var data = await provider.loadThumbnail?.call();
      var mem = MemoryImage(data!);
      return await ImageUtils.imageProviderToImage(mem);
    }

    return await ImageUtils.imageProviderToImage(provider);
  }
}
