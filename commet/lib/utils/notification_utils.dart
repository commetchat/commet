import 'package:commet/main.dart';

class NotificationUtils {
  static (int, int) getNotificationCounts() {
    var highlightedNotificationCount = 0;
    var notificationCount = 0;

    var topLevelSpaces =
        clientManager!.spaces.where((e) => e.isTopLevel).toList();

    for (var i in topLevelSpaces) {
      highlightedNotificationCount += i.displayHighlightedNotificationCount;
      notificationCount += i.displayNotificationCount;
    }

    for (var dm in clientManager!.directMessages.highlightedRoomsList) {
      highlightedNotificationCount += dm.displayNotificationCount;
      notificationCount += dm.displayNotificationCount;
    }

    return (highlightedNotificationCount, notificationCount);
  }
}
