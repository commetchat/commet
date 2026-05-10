import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilitySendStateEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;
  String? eventKey;

  MatrixCapabilitySendStateEvent(
      {required this.runner, required this.eventType, this.eventKey});

  static String name = "org.matrix.msc2762.send.state_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilitySendStateEvent(
          runner: runner, eventType: type!, eventKey: key));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Send State event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action != "send_event") return false;

    var type = message.data.tryGet<String>("type");
    if (type != eventType) return false;

    if (message.data.containsKey("state_key") == false) return false;

    if (eventKey != null && message.data["state_key"] != eventKey) return false;

    return true;
  }

  @override
  void handleRequest(MatrixWidgetMessage message) async {
    var key = message.data.tryGet<String>("state_key");
    var content = message.data.tryGetMap<String, dynamic>("content");

    if (content == null) return;

    var result = await runner.room!.matrixRoom.client
        .setRoomStateWithKey(runner.room!.identifier, eventType, key!, content);

    runner.messageTransport.send(message.createResponse(
        response: {"room_id": runner.room!.identifier, "event_id": result}));

    runner.messageTransport.send(
        runner.eventHandler.generateToWidgetEvent(action: "send_event", data: {
      "content": content,
      "sender": runner.client.self!.identifier,
      "state_key": key,
      "type": eventType,
      "event_id": result,
      "origin_server_ts": DateTime.now().millisecondsSinceEpoch,
      "room_id": runner.room!.identifier
    }));
  }
}
