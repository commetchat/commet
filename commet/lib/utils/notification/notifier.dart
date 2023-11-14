import 'package:commet/utils/notification/notification_content.dart';

abstract class Notifier {
  Future<void> notify(NotificationContent notification);

  bool get hasPermission;

  Future<bool> requestPermission();

  Future<void> init();
}
