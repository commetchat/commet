import 'package:commet/utils/notification/notification_content.dart';

abstract class Notifier {
  Future<void> notify(NotificationContent notification);

  bool get hasPermission;

  bool get needsToken;

  bool get enabled;

  Future<String?> getToken();

  Future<bool> requestPermission();

  Map<String, dynamic>? extraRegistrationData();

  Future<void> init();
}
