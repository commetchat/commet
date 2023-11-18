import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get needsToken => true;

  UnifiedPushNotifier() {
    notifier = AndroidNotifier();

    if (preferences.unifiedPushEnabled == null) {
      FirstTimeSetup.registerPostLoginSetup(UnifiedPushSetup());
    }
  }

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  Future<void> init() async {
    await notifier.init();
    print("Unified push endpoint: ${preferences.unifiedPushEndpoint}");
    UnifiedPush.initialize(onMessage: onMessage);
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Future<void> notify(NotificationContent notification) {
    return notifier.notify(notification);
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

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }

  @override
  Future<bool?> configure(BuildContext context) async {
    await AdaptiveDialog.show(context, builder: (context) {
      return Placeholder();
    }, title: "Unified Push");

    return true;
  }
}
