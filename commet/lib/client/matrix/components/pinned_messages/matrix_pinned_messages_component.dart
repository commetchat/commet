import 'package:commet/client/components/pinned_messages/pinned_messages_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:matrix/matrix_api_lite/model/event_types.dart';

class MatrixPinnedMessagesComponent
    extends PinnedMessagesComponent<MatrixClient, MatrixRoom> {
  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  MatrixPinnedMessagesComponent(this.client, this.room);

  @override
  bool get canPinMessages =>
      room.matrixRoom.canChangeStateEvent(EventTypes.RoomPinnedEvents);

  @override
  List<String> getPinnedMessages() {
    return room.matrixRoom.pinnedEventIds.reversed.toList();
  }

  @override
  Future<void> pinMessage(String eventId) async {
    var pins = room.matrixRoom.pinnedEventIds.toList();
    pins.add(eventId);
    await room.matrixRoom.setPinnedEvents(pins);
  }

  @override
  Future<void> unpinMessage(String eventId) async {
    var pins = room.matrixRoom.pinnedEventIds.toList();
    pins.removeWhere((e) => e == eventId);
    await room.matrixRoom.setPinnedEvents(pins);
  }

  @override
  bool isMessagePinned(String eventId) {
    final state = room.matrixRoom.getState(EventTypes.RoomPinnedEvents);
    if (state == null) {
      return false;
    }

    final pins = state.content["pinned"] as List<dynamic>;
    return pins.contains(eventId);
  }
}
