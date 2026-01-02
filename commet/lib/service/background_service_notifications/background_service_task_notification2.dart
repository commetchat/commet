import 'dart:async';
import 'package:collection/collection.dart';
import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/client/matrix_background/matrix_background_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/database/database_server.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundNotificationsManager2 {
  ServiceInstance? instance;

  BackgroundNotificationsManager2(this.instance);

  Timer? shutdownTimer;

  List<Map<String, dynamic>> queue = List.empty(growable: true);

  Future<void> init() async {
    if (fileCache == null || clientManager == null) {
      await initDatabaseServer();
    }

    if (fileCache == null) {
      fileCache = FileCache.getFileCacheInstance();

      if (fileCache != null) {
        await fileCache?.init();
      }
    }

    if (clientManager == null) {
      clientManager = ClientManager();

      final clients = preferences.getRegisteredMatrixClients();
      if (clients != null) {
        for (var id in clients) {
          var client = MatrixBackgroundClient(databaseId: id);
          Log.i("Adding background matrix client: ${id}");
          await client.init(true, isBackgroundService: true);
          clientManager!.addClient(client);
        }
      }
    }

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

      try {
        NotificationManager.notify(ErrorNotificationContent(
            title: "An error occurred while processing notifications",
            content: "${e} \n\n ${s}"));
      } catch (_) {}
    }

    if (instance != null) {
      Log.i("Stopping background service");
      instance?.stopSelf();
    }
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    try {
      var roomId = data["room_id"] as String?;
      var eventId = data["event_id"] as String?;
      var counts = data["counts"] as String?;

      if (roomId == null || eventId == null) {
        Log.w("TODO: Handle counts: $counts");
        return;
      }

      var client = clientManager!.clients
          .firstWhereOrNull((element) => element.hasRoom(roomId));

      // If the room does not already belong to any of our clients, it must be an invite
      // I couldn't figure out a good way to determine which client received the invite
      // So we will just display a generic notification
      if (client == null) {
        var content = GenericRoomInviteNotificationContent(
          content: "You received an invitation to chat!",
          title: "Room Invite",
        );

        await NotificationManager.notify(content);
        return;
      }

      var directMessages = client.getComponent<DirectMessagesComponent>();

      Log.i("Got direct messages component: ${directMessages}");
      Log.i("Found client: ${client.identifier}");
      var room = client.getRoom(roomId);

      if (room is MatrixBackgroundRoom) {
        await room.init();
      }

      Log.i("Found room: ${room?.displayName}");

      final isDirectMessage =
          directMessages?.isRoomDirectMessage(room!) == true;
      Log.i("Is direct message: $isDirectMessage");

      var event = await room!.getEvent(eventId);

      Log.e("got event: ${event}");

      if (event == null) return;

      var member = await room.fetchMember(event.senderId);

      var content = MessageNotificationContent(
          senderName: member.displayName,
          senderId: event.senderId,
          roomName: room.displayName,
          content: event.plainTextBody,
          eventId: eventId,
          roomId: roomId,
          clientId: client.identifier,
          senderImage: member.avatar,
          roomImageId: room.avatarId,
          senderImageId: member.avatarId,
          roomImage: room.avatar,
          isDirectMessage: isDirectMessage);

      Log.i("Sender image: ${member.avatar}");

      await NotificationManager.notify(content);
    } catch (e, s) {
      Log.e("An error occured while processing the notification service loop");
      Log.onError(e, s);

      NotificationManager.notify(ErrorNotificationContent(
          title: "An error occurred while processing notifications",
          content: "${e} \n\n ${s}"));
    }
  }
}
