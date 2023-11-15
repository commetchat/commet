import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/main.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushNotifier implements Notifier {
  late AndroidNotifier notifier;

  UnifiedPushNotifier() {
    notifier = AndroidNotifier();
  }

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  Future<void> init() async {
    await notifier.init();
    UnifiedPush.initialize(
        onNewEndpoint: onNewEndpoint,
        onMessage: onMessage,
        onRegistrationFailed: onRegistrationFailed,
        onUnregistered: onUnregistered);
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    notifier.notify(notification);
  }

  @override
  Future<bool> requestPermission() {
    return notifier.requestPermission();
  }

  void onNewEndpoint(String endpoint, String instance) {
    print("A new Unified Push gateway has been registered!");
    print(endpoint);
  }

  void onMessage(Uint8List message, String instance) async {
    var data = utf8.decode(message);
    print(data);

    var json = jsonDecode(data) as Map<String, dynamic>;
    var notifData = json['notification'] as Map<String, dynamic>;

    var roomId = notifData['room_id'] as String;
    var event_id = notifData['event_id'] as String;

    var client =
        clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));
    var room = client.getRoom(roomId);
    var event = await room!.getEvent(event_id);

    var user = client.getPeer(event!.senderId);
    await user.loading;

    notifier.notify(MessageNotificationContent(
        senderName: user.displayName,
        roomName: room.displayName,
        content: event.body!,
        eventId: event_id,
        roomId: room.identifier,
        clientId: client.identifier,
        senderImage: user.avatar,
        roomImage: await room.getShortcutImage(),
        isDirectMessage: room.isDirectMessage));
  }

  void onRegistrationFailed(String instance) {}

  void onUnregistered(String instance) {}
}
