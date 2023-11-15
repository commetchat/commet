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

  void onNewEndpoint(String endpoint, String instance) {}

  void onMessage(Uint8List message, String instance) async {
    var space = clientManager!.spaces[1];
    var room = space.rooms.first;
    var user = space.client.self!;

    await user.loading;

    notifier.notify(MessageNotificationContent(
        senderName: user.displayName,
        roomName: room.displayName,
        content: "Test notification",
        eventId: "fake_event_id",
        roomId: room.identifier,
        clientId: space.client.identifier,
        senderImage: user.avatar,
        roomImage: await room.getShortcutImage(),
        isDirectMessage: room.isDirectMessage));
  }

  void onRegistrationFailed(String instance) {}

  void onUnregistered(String instance) {}
}
