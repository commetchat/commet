import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/notification/modifiers/notification_modifiers.dart';
import 'package:commet/utils/notification/notification_content.dart';

class NotificationModifierSuppressActiveRoom implements NotificationModifier {
  String roomId = "";

  NotificationModifierSuppressActiveRoom() {
    EventBus.onRoomOpened.stream.listen((event) {
      roomId = event.identifier;
    });
  }

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (content is! MessageNotificationContent) return content;

    if (content.roomId == roomId) return null;

    return content;
  }
}
