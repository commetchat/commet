import 'package:commet/utils/notification/notification_content.dart';

abstract class NotificationModifier {
  Future<NotificationContent?> process(NotificationContent content);
}
