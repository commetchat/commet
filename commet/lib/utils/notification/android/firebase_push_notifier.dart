import 'package:commet/main.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:fcm_shared_isolate/fcm_shared_isolate.dart';

class FirebasePushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get hasPermission => notifier.hasPermission;

  FcmSharedIsolate? fcm;

  FirebasePushNotifier() {
    notifier = AndroidNotifier();
  }

  @override
  Future<void> init() async {
    await notifier.init();
    fcm = FcmSharedIsolate();
    print("Initialized fcm");

    if (preferences.fcmKey == null) {
      var token = await fcm?.getToken();
      if (token != null) {
        preferences.setFcmKey(token);
        print("Got fcm token:");
      }
    }

    print(preferences.fcmKey);

    fcm?.setListeners(
      onMessage: onMessage,
      onNewToken: onNewToken,
    );
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  void onMessage(Map message) async {
    print(message);
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

    notifier.notify(MessageNotificationContent(
        senderName: user.displayName,
        roomName: room.displayName,
        content: event.body!,
        eventId: eventId,
        roomId: room.identifier,
        clientId: client.identifier,
        senderImage: user.avatar,
        roomImage: await room.getShortcutImage(),
        isDirectMessage: room.isDirectMessage));
  }

  void onNewToken(String token) {}
}
