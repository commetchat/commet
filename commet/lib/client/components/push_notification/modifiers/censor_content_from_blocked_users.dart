import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/main.dart';

class NotificationModifierCensorBlockedUsers implements NotificationModifier {
  @override
  Future<NotificationContent?> process(
    NotificationContent content, {
    Function(String reason)? onNotificationRejected,
  }) async {
    if (content is MessageNotificationContent) {
      var client = clientManager?.getClient(content.clientId);

      if (client?.isUserBlocked(content.senderId) == true) {
        return null;

        // return MessageNotificationContent(
        //   senderName: CommonStrings.placeholderBlockedUser,
        //   senderId: content.senderId,
        //   roomName: CommonStrings.placeholderBlockedUser,
        //   content: "Message from blocked user",
        //   eventId: content.eventId,
        //   roomId: content.roomId,
        //   clientId: content.clientId,
        //   isDirectMessage: content.isDirectMessage,
        // );
      }
    }

    return content;
  }
}
