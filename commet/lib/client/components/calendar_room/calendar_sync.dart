import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';

class CalendarSync {
  CalendarSync._();
  static final instance = CalendarSync._();
  bool isStarted = false;

  Future<void> startSyncing() async {
    if (isStarted) return;
    isStarted = true;

    Log.i("Starting calendar sync");
    // syncAllClients();
  }

  Future<void> syncAllClients() async {
    Log.i("Client Manager: ${clientManager}");

    if (clientManager == null) {
      Timer(Duration(seconds: 30), () => syncAllClients());
    } else {
      await Future.wait([
        for (var client in clientManager!.clients) syncClient(client),
      ]);

      Timer(Duration(minutes: 30), () => syncAllClients());
    }
  }

  Future<void> syncClient(Client client) async {
    // Wait for client to come online
    if (client.connectionStatusChanged.value !=
        ClientConnectionStatus.connected) {
      Log.i(
        "Waiting for client to come online to sync calendar, current status: ${client.connectionStatusChanged.value}",
      );
      while (true) {
        var result = await client.connectionStatusChanged.stream.first;
        if (result.status == ClientConnectionStatus.connected) {
          Log.i("Client is online, continuing");
          break;
        }
      }
    }

    for (var room in client.rooms) {
      var calendar = room.getComponent<CalendarRoom>();

      if (calendar?.syncedCalendars.value?.isNotEmpty == true) {
        Log.i(
          "Syncing room calendar from external sources: ${room.identifier}",
        );

        await calendar!.runCalendarSync();
        await Future.delayed(Duration(seconds: 5));
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    Log.i("Finished syncing all rooms");
  }
}
