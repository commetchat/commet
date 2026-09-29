import 'dart:async';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilityReceiveStateEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;

  // If null, allow all keys
  String? eventKey;

  MatrixCapabilityReceiveStateEvent(
      {required this.runner, required this.eventType, this.eventKey}) {
    sub = runner.client.matrixClient.onRoomState.stream.listen(onEvent);

    Log.i("Created Receive State Event Capability");

    updateState();
  }

  static String name = "org.matrix.msc2762.receive.state_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilityReceiveStateEvent(
          runner: runner, eventType: type!, eventKey: key));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  StreamSubscription? sub;

  @override
  String toString() {
    return "Receive State event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (runner.room == null) return false;

    if (message.action != "org.matrix.msc2876.read_events") return false;

    var type = message.data.tryGet<String>("type");
    if (type != eventType) return false;

    if (eventKey != null &&
        message.data.tryGet<String>("state_key") != eventKey) return false;

    if (message.data.containsKey("state_key") == false) return false;

    return true;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var events = eventKey == null
        ? runner.room!.matrixRoom.states[eventType]?.entries
            .map((i) => i.value)
            .toList()
        : [runner.room!.matrixRoom.states[eventType]?[eventKey]];

    if (events == null || events.nonNulls.isEmpty == true) {
      return message.createResponseObject(response: {
        "events": [],
      });
    }

    var key = message.data.tryGet<String>("state_key");
    if (key != null) {
      events = events.where((i) => i?.stateKey == key).toList();
    }

    var finalEvents = events.nonNulls;

    return message
        .createResponseObject(response: {"events": convertEvents(finalEvents)});
  }

  List<Map<dynamic, dynamic>> convertEvents(
      Iterable<StrippedStateEvent> events) {
    return events.map((i) {
      if (i is Event) {
        return {
          "content": i.content,
          "sender": i.senderId,
          "state_key": i.stateKey!,
          "type": i.type,
          "event_id": i.eventId,
          if (i.unsigned != null) "unsigned": i.unsigned,
          "origin_server_ts": i.originServerTs.millisecondsSinceEpoch,
          "room_id": runner.room!.identifier
        };
      } else if (i is User) {
        return {
          "content": i.content,
          "sender": i.senderId,
          "state_key": i.stateKey!,
          "type": i.type,
          "room_id": runner.room!.identifier
        };
      } else {
        throw UnimplementedError();
      }
    }).toList();
  }

  void onEvent(({String roomId, StrippedStateEvent state}) event) {
    var roomid = event.roomId;
    var state = event.state;

    if (roomid != runner.room!.identifier) return;

    if (state.type != eventType) return;
    if (eventKey != null && state.stateKey != eventKey) return;

    var i = state as MatrixEvent;

    Log.i("Received new state event, notifying widget");

    runner.messageTransport.send(
        runner.eventHandler.generateToWidgetEvent(action: "send_event", data: {
      "type": i.type,
      "sender": i.senderId,
      "content": i.content,
      "origin_server_ts": i.originServerTs.millisecondsSinceEpoch,
      if (i.unsigned != null) "unsigned": i.unsigned,
      "event_id": i.eventId,
      "room_id": i.roomId!,
    }));

    updateState();
  }

  @override
  void dispose() {
    sub?.cancel();
  }

  void updateState() {
    Log.i("Sending initial state: $eventType");
    var events = eventKey == null
        ? runner.room!.matrixRoom.states[eventType]?.entries
            .map((i) => i.value)
            .toList()
        : [runner.room!.matrixRoom.states[eventType]?[eventKey]];

    if (events == null || events.nonNulls.isEmpty == true) {
      runner.messageTransport.send(runner.eventHandler
          .generateToWidgetEvent(action: "update_state", data: {"state": []}));

      return;
    }

    runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
        action: "update_state",
        data: {"state": convertEvents(events.nonNulls)}));
  }
}
