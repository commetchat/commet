import 'dart:async';
import 'dart:collection';

import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/database/database_server.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundNotificationsManager2 {
  ServiceInstance instance;

  BackgroundNotificationsManager2(this.instance);

  Timer? shutdownTimer;

  List<Map<String, dynamic>> queue = List.empty(growable: true);

  Future<void> init() async {
    await initDatabaseServer();

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

    String? clientId;
    Log.i("Finding which client should handle this notification");
    for (var client in clientManager!.clients) {
      Log.i("Client: ${client.identifier}");

      if (client.hasRoom(roomId)) {
        Log.i("Found correct client!");
        clientId = client.identifier;
      }
    }

    var client =
        clientManager!.clients.firstWhere((element) => element.hasRoom(roomId));

    var directMessages = client.getComponent<DirectMessagesComponent>();

    Log.i("Got direct messages component: ${directMessages}");
    Log.i("Found client: ${client.identifier}");
    var room = client.getRoom(roomId);
    Log.i("Found room: ${room?.displayName}");

    final isDirectMessage = directMessages?.isRoomDirectMessage(room!) == true;
    Log.i("Is direct message: $isDirectMessage");

    var event = await room!.getEvent(eventId);

    Log.e("got event: ${event}");

    if (clientId == null) {
      Log.e("Could not find a client to handle this notification");
      return;
    }

    if (event == null) return;

    var member = await room.fetchMember(event.senderId);

    var content = MessageNotificationContent(
        senderName: member.displayName,
        senderId: event.senderId,
        roomName: roomId,
        content: event.plainTextBody,
        eventId: eventId,
        roomId: roomId,
        clientId: clientId,
        senderImage: member.avatar,
        roomImage: null,
        isDirectMessage: isDirectMessage);

    await NotificationManager.notify(content);
  }
}
