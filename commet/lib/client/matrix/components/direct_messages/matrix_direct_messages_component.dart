import 'dart:async';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixDirectMessagesComponent
    extends DirectMessagesComponent<MatrixClient>
    implements NeedsPostLoginInit {
  @override
  MatrixClient client;

  @override
  List<Room> directMessageRooms = [];

  @override
  List<Room> highlightedRoomsList = [];

  @override
  Stream<void> get onRoomsListUpdated => listUpdated.stream;

  @override
  Stream<void> get onHighlightedRoomsListUpdated =>
      highlightedListUpdated.stream;

  StreamController<void> listUpdated = StreamController.broadcast();

  StreamController<void> highlightedListUpdated = StreamController.broadcast();

  String currentRoomId = "";

  MatrixDirectMessagesComponent(this.client) {
    client.getMatrixClient().onSync.stream.listen(onMatrixSync);
    EventBus.onSelectedRoomChanged.stream
        .listen((value) => currentRoomId = value?.identifier ?? "");
  }

  @override
  void postLoginInit() {
    updateRoomsList();
    updateNotificationsList();
    client.onRoomAdded.listen(onRoomAdded);
    client.onRoomRemoved.listen(onRoomRemoved);
  }

  @override
  bool isRoomDirectMessage(Room room) {
    if (room is! MatrixRoom) {
      return false;
    }

    if (room.matrixRoom.isDirectChat) {
      return true;
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
    print(event);

    if (event.accountData?.any((e) => e.type == "m.direct") == true) {
      updateRoomsList();
    }

    if (event.rooms?.join?.entries
            .any((e) => e.value.unreadNotifications != null) ==
        true) {
      updateNotificationsList();
    }
  }

  void onRoomRemoved(int index) {
    var room = client.rooms[index];
    directMessageRooms.remove(room);
    listUpdated.add(null);
  }

  void updateNotificationsList() {
    highlightedRoomsList = directMessageRooms
        .where((e) =>
            e.displayNotificationCount > 0 && e.identifier != currentRoomId)
        .toList();

    highlightedListUpdated.add(null);
  }
}
