import 'package:commet/utils/notification/modifiers/notification_modifiers.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:intl/intl.dart';

class NotificationModifierHideContent implements NotificationModifier {
  String get notificationModifiersPrivacyEnhanced => Intl.message(
      "Sent a message",
      name: "notificationModifiersPrivacyEnhanced",
      desc:
          "Placeholder text to put in a notification when the user has privacy enhanced notifications enabled.");

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    content.content = "A Notification was received";

    if (content is MessageNotificationContent) {
      content.content = notificationModifiersPrivacyEnhanced;
    }

    return content;
  }
}
