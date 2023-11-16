import 'package:commet/main.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  if (clientManager == null) {
    await initNecessary();
  }

  var data = message.data;
  String? eventId = data['event_id'];
  String? roomId = data['room_id'];
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
      roomName: room.displayName,
      content: event.body!,
      eventId: eventId,
      roomId: room.identifier,
      clientId: client.identifier,
      senderImage: user.avatar,
      roomImage: await room.getShortcutImage(),
      isDirectMessage: room.isDirectMessage));
}

Future<void> onMessage(RemoteMessage message) async {
  print("Received firebase message!");

  var data = message.data;
  String? eventId = data['event_id'];
  String? roomId = data['room_id'];
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
      roomName: room.displayName,
      content: event.body!,
      eventId: eventId,
      roomId: room.identifier,
      clientId: client.identifier,
      senderImage: user.avatar,
      roomImage: await room.getShortcutImage(),
      isDirectMessage: room.isDirectMessage));

/*
*/
}

class FirebasePushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get hasPermission => notifier.hasPermission;

  FirebasePushNotifier() {
    notifier = AndroidNotifier();
  }

  @override
  Future<void> init() async {
    await notifier.init();
    print("Initialized fcm");
    print(preferences.fcmKey);

    await Firebase.initializeApp();
    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  void onNewToken(String token) {}
}
