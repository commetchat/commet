import 'package:commet/main.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
// import 'package:fcm_shared_isolate/fcm_shared_isolate.dart';

Future<void> onMessage(dynamic message) async {
  String? eventId = message['event_id'];
  String? roomId = message['room_id'];
  if (eventId == null || roomId == null) {
    return;
  }

  var client =
      clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));
  var room = client.getRoom(roomId);
  var event = await room!.getEvent(eventId);

  var user = client.getPeer(event!.senderId);
  await user.loading;

  notificationManager.notify(MessageNotificationContent(
      senderName: user.displayName,
      senderId: user.identifier,
      roomName: room.displayName,
      content: event.body!,
      eventId: eventId,
      roomId: room.identifier,
      clientId: client.identifier,
      senderImage: user.avatar,
      roomImage: await room.getShortcutImage(),
      isDirectMessage: room.isDirectMessage));
}

class FirebasePushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  bool get needsToken => true;

  FirebasePushNotifier() {
    notifier = AndroidNotifier();
  }

  @override
  bool get enabled => true;

  dynamic fcm;

  @override
  Future<void> init() async {
    await notifier.init();

    var key = await fcm.getToken();

    preferences.setFcmKey(key);

    preferences.setPushGateway("push.commet.chat");
    fcm.setListeners(onMessage: onMessage);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  @override
  Future<String?> getToken() {
    return fcm.getToken();
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return {"type": "fcm"};
  }
}
