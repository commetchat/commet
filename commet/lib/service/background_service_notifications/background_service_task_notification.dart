import 'dart:async';
import 'dart:collection';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/service/background_service_task.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceTaskNotification extends BackgroundServiceTask {
  String roomId;
  String eventId;

  BackgroundServiceTaskNotification(this.roomId, this.eventId);
}

class BackgroundNotificationsManager {
  ServiceInstance instance;

  BackgroundNotificationsManager(this.instance);

  Timer? shutdownTimer;

  List<Map<String, dynamic>> queue = List.empty(growable: true);

  Future<void> init() async {
    isHeadless = true;
    await NotificationManager.init();

    if (fileCache == null) {
      fileCache = FileCache.getFileCacheInstance();

      if (fileCache != null) {
        await fileCache?.init();
      }
    }

    shortcutsManager.init();

    clientManager = await ClientManager.init(isBackgroundService: true);
  }

  void onReceived(Map<String, dynamic>? data) async {
    if (data != null) {
      queue.add(data);
      Log.i("Received message, adding to queue: (${queue.length}) $data");
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

    // for (var client in clientManager!.clients) {
    //   Log.i("Looking for room: $roomId in client ${client.identifier}");

    //   for (var room in client.rooms) {
    //     Log.i("Has room: ${room.displayName}   (${room.identifier})");
    //   }
    // }

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
  }
}
