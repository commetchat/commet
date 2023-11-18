import 'package:commet/utils/notification/notification_content.dart';
import 'package:flutter/material.dart';

abstract class Notifier {
  Future<void> notify(NotificationContent notification);

  bool get hasPermission;

  bool get needsToken;

  Future<String?> getToken();

  Future<bool> requestPermission();

  Map<String, dynamic>? extraRegistrationData();

  /// Returns null if user configuration was not necessary, return true if was configured, return false if not configured
  Future<bool?> configure(BuildContext context);

  Future<void> init();
}
