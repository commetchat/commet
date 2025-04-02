import 'dart:async';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';

class IOSNotificationMutator {
  Completer completer;

  IOSNotificationMutator(this.completer);

  Future<void> init() async {
    isHeadless = true;

    if (fileCache == null) {
      fileCache = FileCache.getFileCacheInstance();

      if (fileCache != null) {
        await fileCache?.init();
      }
    }

    shortcutsManager.init();

    clientManager = await ClientManager.init(isBackgroundService: true);
  }

  Future<Map<String, String>> handleMessage(Map<String, dynamic>? data) async {
    if (data == null) {
      completer.complete();
      return {
        "title": "New Message",
        "subtitle": "",
        "body": "Received Message"
      };
    }

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

    if (event is TimelineEventEncrypted) {
      var decrypted = await event.attemptDecrypt(room);
      event = decrypted ?? event;
    }

    var content = {
      "title": user.displayName,
      "subtitle": room.displayName,
      "body": event.plainTextBody
    };
    completer.complete();
    return content;
  }

  void channelHandler({channel}) async {
    channel.setMethodCallHandler((call) async {
      handleMessage(call.arguments);
    });
  }
}
