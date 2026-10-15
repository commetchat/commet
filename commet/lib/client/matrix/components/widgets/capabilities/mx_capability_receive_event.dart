import 'dart:async';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:matrix/src/event.dart';

class MatrixCapabilityReceiveEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;

  String? eventKey;

  StreamSubscription? sub;

  MatrixCapabilityReceiveEvent(
      {required this.runner, required this.eventType, this.eventKey}) {
    sub = runner.client.matrixClient.onTimelineEvent.stream.listen(onEvent);
  }

  @override
  String toString() {
    return "Receive Event: $eventType";
  }

  static const String name = "org.matrix.msc2762.receive.event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilityReceiveEvent(
          runner: runner, eventType: type!, eventKey: key));

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var timeline = (runner.room?.timeline ?? await runner.room!.getTimeline())
        as MatrixTimeline;

    var events = timeline.matrixTimeline!.events;

    var filtered = events.where((i) => canGetEvent(i));

    var result = filtered
        .map((i) => {
              "type": i.type,
              "sender": i.senderId,
              "content": i.content,
              "origin_server_ts": i.originServerTs.millisecondsSinceEpoch,
              if (i.unsigned != null) "unsigned": i.unsigned,
              "event_id": i.eventId,
              "room_id": i.roomId!,
            })
        .toList();

    return message.createResponseObject(response: {"events": result});
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (runner.room == null) return false;

    if (message.action != "org.matrix.msc2876.read_events") return false;

    var type = message.data.tryGet<String>("type");

    if (type != eventType) return false;

    var key = message.data.tryGet<String>("msgtype");

    if (eventKey != null && key != eventKey) return false;

    if (message.data.containsKey("state_key")) return false;

    return true;
  }

  void onEvent(Event event) {
    if (runner.room == null) return;

    if (event.roomId != runner.room!.identifier) return;

    // Filter out events from fake sync in matrix sdk
    if (event.eventId.startsWith("\$") == false) {
      return;
    }

    if (event.status != EventStatus.synced) return;

    if (canGetEvent(event) == false) return;

    Log.i("Sending new event that came in!");

    var i = event;
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
  }

  bool canGetEvent(Event i) {
    if (i.type != eventType) return false;

    if (eventKey != null) {
      if (i.content["msgtype"] != eventKey) {
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    sub?.cancel();
  }
}
