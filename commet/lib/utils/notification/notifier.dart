import 'package:commet/config/build_config.dart';
import 'package:commet/utils/notification/linux/linux_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/windows/windows_notifier.dart';

abstract class Notifier {
  Future<void> notify(NotificationContent notification);

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
