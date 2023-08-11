import 'package:flutter/material.dart';

import 'notification_manager.dart';

abstract class Notifier {
  @protected
  Future<void> notifyInternal(NotificationContent notification);

  Future<void> notify(NotificationContent notification) async {
    if (!hasPermission) {
      await requestPermission();
    }

    if (hasPermission) {
      notifyInternal(notification);
    }
  }

  bool get hasPermission;

  Future<bool> requestPermission();
}
