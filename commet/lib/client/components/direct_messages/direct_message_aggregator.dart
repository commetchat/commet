import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/notifying_list_mapped.dart';

class DirectMessagesAggregator implements DirectMessagesInterface {
  ClientManager clientManager;

  @override
  late INotifyingList<Room> directMessageRooms;

  @override
  late INotifyingList<Room> highlightedRoomsList;

  final StreamController updatedController = StreamController.broadcast();

  final StreamController highlightedUpdateController =
      StreamController.broadcast();

  final StreamController<void> onEventReceived = StreamController.broadcast();

  DirectMessagesAggregator(this.clientManager) {
    directMessageRooms = NotifyingListMapped<Room, Client>(
      baseList: clientManager.clients,
      map: (value) {
        final comp = value.getComponent<DirectMessagesComponent>();
        return comp!.directMessageRooms;
      },
    );

    highlightedRoomsList = NotifyingListMapped<Room, Client>(
      baseList: clientManager.clients,
      map: (value) {
        final comp = value.getComponent<DirectMessagesComponent>();
        return comp!.highlightedRoomsList;
      },
    );

    clientManager.onEventReceived.listen(_onEvent);

    highlightedRoomsList.onListUpdated.listen((_) {
      Log.i("Highlihgted rooms list updated!");
    });
  }

  void _onEvent((Client, Room, TimelineEvent) event) {
    if (event.$3 is! TimelineEventMessage) {
      return;
    }

    var client = event.$1;

    var comp = client.getComponent<DirectMessagesComponent>();

    if (comp?.isRoomDirectMessage(event.$2) == true) {
      onEventReceived.add(null);
    }
  }
}
