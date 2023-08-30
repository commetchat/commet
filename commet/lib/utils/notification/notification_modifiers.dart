import 'package:commet/utils/notification/notification_manager.dart';
import 'package:intl/intl.dart';

class NotificationModifiers {
  // Tweaks a notification to hide the body of the text
  static NotificationModifier privacyEnhanced = (content) async {
    content.content = Intl.message("Sent a message",
        name: "notificationMessageBodyPrivacyEnhancedMode",
        desc:
            "Placeholder text to put in a notification when the user has privacy enhanced notifications enabled.");
    return content;
  };

  // Disables all notifications
  static NotificationModifier doNotDisturb = (content) async {
    return null;
  };
}
