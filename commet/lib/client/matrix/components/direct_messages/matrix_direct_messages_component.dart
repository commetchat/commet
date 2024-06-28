import 'dart:async';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixDirectMessagesComponent
    extends DirectMessagesComponent<MatrixClient>
    implements NeedsPostLoginInit {
  @override
  MatrixClient client;

  MatrixDirectMessagesComponent(this.client) {
    client.getMatrixClient().onSync.stream.listen(onMatrixSync);
  }

  @override
  List<Room> directMessageRooms = [];

  StreamController<void> listUpdated = StreamController.broadcast();

  @override
  Stream<void> get onDirectMessagesUpdated => listUpdated.stream;

  @override
  void postLoginInit() {
    updateRoomsList();
    client.onRoomAdded.listen(onRoomAdded);
  }

  @override
  bool isRoomDirectMessage(Room room) {
    if (room is! MatrixRoom) {
      return false;
    }

    if (room.matrixRoom.isDirectChat) {
      return true;
    }

    var memberStates = room.matrixRoom.states["m.room.member"];
    if (memberStates?.length == 2) {
      //this might be a direct message room that hasnt been added to account data properly
      for (var key in memberStates!.keys) {
        var state = memberStates[key];
        if (state?.prevContent?["is_direct"] == true) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  String? getDirectMessagePartnerId(Room room) {
    if (room is! MatrixRoom) {
      return null;
    }

    if (room.matrixRoom.directChatMatrixID != null) {
      return room.matrixRoom.directChatMatrixID;
    }

    var memberStates = room.matrixRoom.states["m.room.member"];
    if (memberStates?.length == 2) {
      //this might be a direct message room that hasnt been added to account data properly
      for (var key in memberStates!.keys) {
        var state = memberStates[key];
        if (state?.prevContent?["is_direct"] == true) {
          return key;
        }
      }
    }

    return null;
  }

  @override
  Future<Room?> createDirectMessage(String userId) async {
    var mx = client.getMatrixClient();
    var roomId = await mx.startDirectChat(userId);

    return client.getRoom(roomId);
  }

  void onRoomAdded(int index) {
    var room = client.rooms[index];
    if (isRoomDirectMessage(room)) {
      updateRoomsList();
    }
  }

  void updateRoomsList() {
    directMessageRooms =
        client.rooms.where((r) => isRoomDirectMessage(r)).toList();

    listUpdated.add(null);
  }

  void onMatrixSync(SyncUpdate event) {
    if (event.accountData == null) {
      return;
    }

    if (event.accountData!.any((e) => e.type == "m.direct")) {
      updateRoomsList();
    }
  }
}
