import 'package:commet/main.dart';

class NotificationUtils {
  static (int, int) getNotificationCounts() {
    return _getNotificationCounts(includeSingleRooms: false);
  }

  static (int, int) getTrayNotificationCounts() {
    return _getNotificationCounts(includeSingleRooms: true);
  }

  static (int, int) _getNotificationCounts({required bool includeSingleRooms}) {
    var highlightedNotificationCount = 0;
    var notificationCount = 0;

    var topLevelSpaces =
        clientManager!.spaces.where((e) => e.isTopLevel).toList();

    for (var i in topLevelSpaces) {
      highlightedNotificationCount += i.displayHighlightedNotificationCount;
      notificationCount += i.displayNotificationCount;
    }

    if (includeSingleRooms) {
      // Include rooms that are not part of any space and are not direct messages.
      for (var room in clientManager!.singleRooms()) {
        highlightedNotificationCount += room.displayHighlightedNotificationCount;
        notificationCount += room.displayNotificationCount;
      }
    }

    for (var dm in clientManager!.directMessages.highlightedRoomsList) {
      highlightedNotificationCount += dm.displayHighlightedNotificationCount;
      notificationCount += dm.displayNotificationCount;
    }

    return (highlightedNotificationCount, notificationCount);
  }
}
