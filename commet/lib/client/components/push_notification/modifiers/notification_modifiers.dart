import 'package:commet/client/components/push_notification/notification_content.dart';

abstract class NotificationModifier {
  Future<NotificationContent?> process(NotificationContent content);
}
