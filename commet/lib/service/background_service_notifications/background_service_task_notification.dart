import 'dart:async';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceTaskNotification extends BackgroundServiceTask {
  String roomId;
  String eventId;

  BackgroundServiceTaskNotification(this.roomId, this.eventId);
}

class BackgroundNotificationsManager {
  ServiceInstance instance;

  BackgroundNotificationsManager(this.instance);

  Future<ClientManager>? loadingManager;

  Timer? shutdownTimer;
  int numRequests = 0;

  void onReceived(Map<String, dynamic>? data) async {
    numRequests += 1;
    isHeadless = true;

    Log.i("Received message from main isolate: $data");

    if (shutdownTimer != null) {
      Log.i("Cancelling shutdown, new event came in");
      shutdownTimer!.cancel();
      shutdownTimer = null;
    }

    await NotificationManager.init();
    if (fileCache == null) {
      fileCache = FileCache.getFileCacheInstance();

      if (fileCache != null) {
        await fileCache?.init();
      }
    }

    shortcutsManager.init();

    if (data == null ||
        !data.containsKey("room_id") ||
        !data.containsKey("event_id")) {
      Log.i("Invalid call to BackgroundNotificationsManager.onReceived");
      return;
    }

    if (clientManager == null) {
      if (loadingManager != null) {
        await loadingManager;
      } else {
        loadingManager = ClientManager.init(isBackgroundService: true);
        clientManager = await loadingManager!;
      }
    }

    if (clientManager == null) {
      Log.i("Could not get instance of client manager!");
    }

    var roomId = data["room_id"] as String;
    var eventId = data["event_id"] as String;

    var client =
        clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));

    Log.i("Found client: ${client.identifier}");
    var room = client.getRoom(roomId);
    Log.i("Found room: ${room?.displayName}");

    var event = await room!.getEvent(eventId);
    var user = client.getPeer(event!.senderId);
    await user.loading;

    Log.i("Got user: $user  (${user.avatar})");

    Log.i("Got event: ${event.body}");
    Log.i("Received background notification data: $event");

    Log.i(event.type);

    if (event.type == EventType.message || event.type == EventType.encrypted) {
      await NotificationManager.notify(MessageNotificationContent(
          senderName: user.displayName,
          senderId: user.identifier,
          roomName: room.displayName,
          content: event.body!,
          eventId: eventId,
          roomId: room.identifier,
          clientId: client.identifier,
          senderImage: user.avatar,
          roomImage: room.avatar,
          isDirectMessage: room.isDirectMessage));
    }

    numRequests -= 1;

    if (numRequests == 0) {
      shutdownTimer = Timer(const Duration(milliseconds: 500), () {
        instance.stopSelf();
      });
    }
  }
}
