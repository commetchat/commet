import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/stale_info.dart';

class DirectMessagesAggregator implements DirectMessagesInterface {
  ClientManager clientManager;

  @override
  late List<Room> directMessageRooms;

  @override
  late List<Room> highlightedRoomsList;

  @override
  Stream<void> get onHighlightedRoomsListUpdated =>
      highlightedUpdateController.stream;

  @override
  Stream<void> get onRoomsListUpdated => updatedController.stream;

  final StreamController updatedController = StreamController.broadcast();

  final StreamController highlightedUpdateController =
      StreamController.broadcast();

  DirectMessagesAggregator(this.clientManager) {
    updateDirectMessageRooms();
    for (var client in clientManager.clients) {
      final comp = client.getComponent<DirectMessagesComponent>();
      comp?.onRoomsListUpdated.listen(onClientUpdatedList);
      comp?.onHighlightedRoomsListUpdated.listen(onHighlightedListUpdated);
    }

    clientManager.onClientAdded.stream.listen(onClientAdded);
    clientManager.onClientRemoved.stream.listen(onClientRemoved);
  }

  void updateDirectMessageRooms() {
    var list = List<Room>.empty(growable: true);
    var highlightedList = List<Room>.empty(growable: true);

    for (var client in clientManager.clients) {
      final comp = client.getComponent<DirectMessagesComponent>();
      if (comp == null) continue;

      list.addAll(comp.directMessageRooms);
      highlightedList.addAll(comp.highlightedRoomsList);
    }

    directMessageRooms = list;
    highlightedRoomsList = highlightedList;

    updatedController.add(null);
    highlightedUpdateController.add(null);
  }

  void onClientUpdatedList(void event) {
    updateDirectMessageRooms();
  }

  void onClientAdded(int index) {
    var client = clientManager.clients[index];
    final comp = client.getComponent<DirectMessagesComponent>();
    if (comp != null) {
      comp.onRoomsListUpdated.listen(onClientUpdatedList);
      comp.onHighlightedRoomsListUpdated.listen(onHighlightedListUpdated);
      updateDirectMessageRooms();
    }
  }

  void onClientRemoved(StalePeerInfo event) {
    updateDirectMessageRooms();
  }

  void onHighlightedListUpdated(void event) {
    updateDirectMessageRooms();
  }
}
