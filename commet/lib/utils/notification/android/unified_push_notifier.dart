import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/main.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:commet/utils/notification/android/android_notifier.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushNotifier implements Notifier {
  late AndroidNotifier notifier;

  @override
  bool get needsToken => true;

  bool isInit = false;

  UnifiedPushNotifier() {
    notifier = AndroidNotifier();

    if (preferences.unifiedPushEnabled == null) {
      FirstTimeSetup.registerPostLoginSetup(UnifiedPushSetup());
    }
  }

  StreamController<String> onEndpointChanged = StreamController.broadcast();

  String? _distributor;

  String? get distributor => _distributor;

  String? get endpoint => preferences.unifiedPushEndpoint;

  @override
  bool get enabled => preferences.unifiedPushEnabled == true;

  @override
  bool get hasPermission => notifier.hasPermission;

  @override
  Future<void> init() async {
    if (isInit) return;
    if (preferences.unifiedPushEnabled != true) return;

    await notifier.init();

    UnifiedPush.initialize(onMessage: onMessage, onNewEndpoint: onNewEndpoint);
    await UnifiedPush.getDistributor().then((value) {
      _distributor = value;
    });

    isInit = true;
  }

  @override
  Future<String?> getToken() async {
    return preferences.unifiedPushEndpoint;
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
    preferences.setUnifiedPushEndpoint(endpoint);
    onEndpointChanged.add(endpoint);
  }

  void onMessage(Uint8List message, String instance) async {
    var data = utf8.decode(message);

    var json = jsonDecode(data) as Map<String, dynamic>;
    var notifData = json['notification'] as Map<String, dynamic>;

    var roomId = notifData['room_id'] as String;
    var eventId = notifData['event_id'] as String;

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

  void onRegistrationFailed(String instance) {}

  void onUnregistered(String instance) {}

  void unregister() async {
    await UnifiedPush.unregister();
    preferences.setUnifiedPushEnabled(false);
    preferences.setUnifiedPushEndpoint(null);
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return null;
  }
}
