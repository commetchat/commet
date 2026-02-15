import 'dart:async';
import 'dart:collection';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
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
    Log.i("Initializing Background Notifications Manager!");

    isHeadless = true;
    await NotificationManager.init(isBackgroundService: true);

    if (fileCache == null) {
      fileCache = FileCache.getFileCacheInstance();

      if (fileCache != null) {
        await fileCache?.init();
      }
    }

    shortcutsManager.init();

    await ClientManager.init(isBackgroundService: true);
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

    Log.i("Stopping background service");
    instance.stopSelf();
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    var roomId = data["room_id"] as String;
    var eventId = data["event_id"] as String;

    var client =
        clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));

    Log.i("Found client: ${client.identifier}");
    var room = client.getRoom(roomId);
    Log.i("Found room: ${room?.displayName}");

    var event = await room!.getEvent(eventId);
    Member? user = await room.fetchMember(event!.senderId);

    Log.i("Got user: $user  ($user)");

    bool isDirectMessage = client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(room) ??
        false;

    if (event is TimelineEventEncrypted) {
      var decrypted = await event.attemptDecrypt(room);
      event = decrypted ?? event;
    }

    if (event is TimelineEventMessage ||
        event is TimelineEventSticker ||
        event is TimelineEventEncrypted) {
      var content = MessageNotificationContent(
          senderName: user.displayName,
          senderId: user.identifier,
          roomName: room.displayName,
          content: event.plainTextBody,
          eventId: eventId,
          roomId: room.roomId,
          clientId: client.identifier,
          senderImage: user.avatar,
          roomImage: room.avatar,
          isDirectMessage: isDirectMessage);

      await NotificationManager.notify(content);
    }
  }
}
