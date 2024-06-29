import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

abstract class DirectMessagesInterface {
  List<Room> get directMessageRooms;

  List<Room> get highlightedRoomsList;

  Stream<void> get onRoomsListUpdated;

  Stream<void> get onHighlightedRoomsListUpdated;
}

abstract class DirectMessagesComponent<T extends Client>
    implements Component<T>, DirectMessagesInterface {
  bool isRoomDirectMessage(Room room);

  String? getDirectMessagePartnerId(Room room);

  /// Open a new direct message with another user
  Future<Room?> createDirectMessage(String userId);
}
