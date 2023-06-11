import 'package:commet/config/build_config.dart';
import 'package:commet/utils/notification/linux/linux_notifier.dart';
import 'package:commet/utils/notification/windows/windows_notifier.dart';
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

  static Future<void> init() async {
    if (BuildConfig.WINDOWS) {
      await WindowsNotifier.init();
    }

    if (BuildConfig.LINUX) {
      await LinuxNotifier.init();
    }
  }
}
