import 'package:commet/utils/notification/notification_manager.dart';

import '../../generated/l10n.dart';

class NotificationModifiers {
  // Tweaks a notification to hide the body of the text
  static NotificationModifier privacyEnhanced = (content) {
    content.content = T.current.notificationReceivedMessagePlaceholder;
    return content;
  };

  // Disables all notifications
  static NotificationModifier doNotDisturb = (content) {
    return null;
  };
}
