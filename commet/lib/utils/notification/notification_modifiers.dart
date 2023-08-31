import 'package:commet/utils/notification/notification_manager.dart';
import 'package:intl/intl.dart';

class NotificationModifiers {
  static String get notificationModifiersPrivacyEnhanced => Intl.message(
      "Sent a message",
      name: "notificationModifiersPrivacyEnhanced",
      desc:
          "Placeholder text to put in a notification when the user has privacy enhanced notifications enabled.");

  // Tweaks a notification to hide the body of the text
  static NotificationModifier privacyEnhanced = (content) async {
    content.content = notificationModifiersPrivacyEnhanced;
    return content;
  };

  // Disables all notifications
  static NotificationModifier doNotDisturb = (content) async {
    return null;
  };
}
