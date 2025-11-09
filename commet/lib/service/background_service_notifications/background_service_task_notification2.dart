import 'dart:async';
import 'dart:collection';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundNotificationsManager2 {
  ServiceInstance instance;

  BackgroundNotificationsManager2(this.instance);

  Timer? shutdownTimer;

  List<Map<String, dynamic>> queue = List.empty(growable: true);

  Future<void> init() async {
    await NotificationManager.init(isBackgroundService: true);
  }

  void onReceived(Map<String, dynamic>? data) async {
    if (data != null) {
      queue.add(data);
      Log.i("[NEW] Received message, adding to queue: (${queue.length}) $data");
    }
  }

  Future<void> flushQueueLoop() async {
    try {
      while (true) {
        if (queue.isEmpty) {
          Log.i("Queue was empty, waiting a sec and double checking");
          await Future.delayed(const Duration(seconds: 1));

          if (queue.isEmpty) {
            Log.i("Queue clear, exiting");
            break;
          } else {
            Log.i("Something new came in, continuing");
          }
        }

        var entry = queue.firstOrNull;
        if (entry != null) {
          Log.i("Processing entry: $entry");
          Log.i("Current queue length: ${queue.length}");
          queue.remove(entry);
          await handleMessage(entry);
        }
      }
    } catch (e, s) {
      Log.e("An error occured while processing the notification service loop");
      Log.onError(e, s);
    }

    instance.stopSelf();
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    var roomId = data["room_id"] as String;
    var eventId = data["event_id"] as String;

    var content = MessageNotificationContent(
        senderName: eventId,
        senderId: eventId,
        roomName: roomId,
        content: eventId,
        eventId: eventId,
        roomId: roomId,
        clientId: "",
        senderImage: null,
        roomImage: null,
        isDirectMessage: false);

    await NotificationManager.notify(content);
  }
}
