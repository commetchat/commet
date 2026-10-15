import 'dart:convert';

import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';

class MatrixBackgroundClientDirectMessagesComponent
    extends DirectMessagesComponent<MatrixBackgroundClient> {
  @override
  MatrixBackgroundClient client;

  MatrixBackgroundClientDirectMessagesComponent(this.client);

  @override
  Future<Room?> createDirectMessage(String userId) {
    throw UnimplementedError();
  }

  @override
  String? getDirectMessagePartnerId(Room room) {
    for (var accountData in client.accountData) {
      if (accountData.type == "m.direct") {
        Log.i("${accountData.type}");
        Log.i("account data: ${accountData.content}");

        var content = jsonDecode(accountData.content) as Map<String, dynamic>;
        for (var pair in content.entries) {
          var key = pair.key;
          var item = pair.value;
          Log.i(item);
          var list = item as List<dynamic>;
          if (list.contains(room.identifier)) {
            return key;
          }
        }
      }
    }

    return null;
  }

  @override
  bool isRoomDirectMessage(Room room) {
    Log.i("Checking if room is direct message");
    for (var accountData in client.accountData) {
      if (accountData.type == "m.direct") {
        Log.i("${accountData.type}");
        Log.i("account data: ${accountData.content}");

        var content = jsonDecode(accountData.content) as Map<String, dynamic>;
        for (var item in content.values) {
          Log.i(item);
          var list = item as List<dynamic>;
          if (list.contains(room.identifier)) {
            Log.i("Found room id in account info, this is a direct message");
            return true;
          }
        }
      }
    }

    Log.i("Could not find room id in account info");
    return false;
  }

  @override
  // TODO: implement directMessageRooms
  INotifyingList<Room> get directMessageRooms => throw UnimplementedError();

  @override
  // TODO: implement highlightedRoomsList
  INotifyingList<Room> get highlightedRoomsList => throw UnimplementedError();
}
