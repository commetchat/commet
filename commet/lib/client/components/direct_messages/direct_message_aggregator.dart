import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/stale_info.dart';

class DirectMessagesAggregator implements DirectMessagesInterface {
  ClientManager clientManager;

  DirectMessagesAggregator(this.clientManager) {
    updateDirectMessageRooms();
    for (var client in clientManager.clients) {
      final comp = client.getComponent<DirectMessagesComponent>();
      comp?.onDirectMessagesUpdated.listen(onClientUpdatedList);
    }

    clientManager.onClientAdded.stream.listen(onClientAdded);
    clientManager.onClientRemoved.stream.listen(onClientRemoved);
  }

  @override
  late List<Room> directMessageRooms;

  final StreamController updatedController = StreamController.broadcast();

  @override
  Stream<void> get onDirectMessagesUpdated => updatedController.stream;

  void updateDirectMessageRooms() {
    var list = List<Room>.empty(growable: true);

    for (var client in clientManager.clients) {
      final comp = client.getComponent<DirectMessagesComponent>();
      if (comp == null) continue;

      list.addAll(comp.directMessageRooms);
    }

    directMessageRooms = list;
    updatedController.add(null);
  }

  void onClientUpdatedList(void event) {
    updateDirectMessageRooms();
  }

  void onClientAdded(int index) {
    var client = clientManager.clients[index];
    final comp = client.getComponent<DirectMessagesComponent>();
    if (comp != null) {
      comp.onDirectMessagesUpdated.listen(onClientUpdatedList);
      updateDirectMessageRooms();
    }
  }

  void onClientRemoved(StalePeerInfo event) {
    updateDirectMessageRooms();
  }
}
