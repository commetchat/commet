import 'package:commet/utils/notification/modifiers/notification_modifiers.dart';
import 'package:commet/utils/notification/notification_content.dart';

class NotificationModifierDoNotDisturb implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    return null;
  }
}
