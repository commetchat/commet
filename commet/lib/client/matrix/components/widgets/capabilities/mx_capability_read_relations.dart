import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:matrix/matrix_api_lite.dart';

class MatrixCapabilityReadEventRelations implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityReadEventRelations({required this.runner});

  static const String name = "org.matrix.msc3869.read_relations";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) =>
          MatrixCapabilityReadEventRelations(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Read Event Relations";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action != name) return false;

    var eventId = message.data.tryGet<String>("event_id");

    if (eventId == null) return false;

    return true;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var eventId = message.data.tryGet<String>("event_id")!;

    var event = await runner.room!.matrixRoom.getEventById(eventId);
    if (event == null) {
      return message.createResponseError(message: "Invalid request");
    }

    var eventType = message.data.tryGet<String>("event_type");

    if (capabilities.canWidgetReadEvent(event) == false) {
      return message.createResponseError(
          message:
              "Rejected: Cannot read type of requested event: ${event.eventId} (${event.type})");
    }

    var relType = message.data.tryGet<String>("rel_type");

    List<MatrixEvent> chunk;
    String? prevBatch;
    String? nextBatch;

    if (eventType != null && relType != null) {
      var result = await runner.room!.matrixRoom.client
          .getRelatingEventsWithRelTypeAndEventType(
              runner.room!.identifier, eventId, relType, eventType);

      chunk = result.chunk;
      prevBatch = result.prevBatch;
      nextBatch = result.nextBatch;
    } else if (relType != null) {
      var result = await runner.room!.matrixRoom.client
          .getRelatingEventsWithRelType(
              runner.room!.identifier, eventId, relType);

      chunk = result.chunk;
      prevBatch = result.prevBatch;
      nextBatch = result.nextBatch;
    } else {
      var result = await runner.room!.matrixRoom.client.getRelatingEvents(
        runner.room!.identifier,
        eventId,
      );

      chunk = result.chunk;
      prevBatch = result.prevBatch;
      nextBatch = result.nextBatch;
    }

    var allowedEvents = chunk.where((i) => capabilities.canWidgetReadEvent(i));
    var response = message.createResponseObject(response: {
      "next_batch": nextBatch,
      "prev_batch": prevBatch,
      "chunk": allowedEvents
          .map((i) => {
                "content": i.content,
                "sender": i.senderId,
                if (i.stateKey != null) "state_key": i.stateKey!,
                "type": i.type,
                "event_id": i.eventId,
                "origin_server_ts": i.originServerTs.millisecondsSinceEpoch,
                "room_id": runner.room!.identifier
              })
          .toList()
    });
    return response;
  }

  @override
  void dispose() {}
}
