import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:intl/intl.dart';

abstract class NotificationModifier {
  NotificationContent? process(NotificationContent content);
}

class NotificationModifierDoNotDisturb implements NotificationModifier {
  @override
  NotificationContent? process(NotificationContent content) {
    return null;
  }
}

class NotificationModifierHideContent implements NotificationModifier {
  String get notificationModifiersPrivacyEnhanced => Intl.message(
      "Sent a message",
      name: "notificationModifiersPrivacyEnhanced",
      desc:
          "Placeholder text to put in a notification when the user has privacy enhanced notifications enabled.");

  @override
  NotificationContent? process(NotificationContent content) {
    content.content = "A Notification was received";

    if (content is MessageNotificationContent) {
      content.content = notificationModifiersPrivacyEnhanced;
    }

    return content;
  }
}

class NotificationModifierDontNotifyActiveRoom implements NotificationModifier {
  String roomId = "";

  NotificationModifierDontNotifyActiveRoom() {
    EventBus.onRoomOpened.stream.listen((event) {
      roomId = event.identifier;
    });
  }

  @override
  NotificationContent? process(NotificationContent content) {
    if (content is! MessageNotificationContent) return content;

    if (content.roomId == roomId) return null;

    return content;
  }
}
