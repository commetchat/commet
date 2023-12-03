import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';

class NotificationModifierDoNotDisturb implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    return null;
  }
}
