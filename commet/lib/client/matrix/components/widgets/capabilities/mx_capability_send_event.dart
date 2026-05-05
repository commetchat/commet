import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilitySendEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;
  String? eventKey;

  MatrixCapabilitySendEvent(
      {required this.runner, required this.eventType, this.eventKey});

  static String name = "org.matrix.msc2762.send.event";

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Send Event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (runner.room == null) return false;

    if (message.action != "send_event") return false;

    var content = message.data.tryGetMap<String, dynamic>("content");

    var type = message.data.tryGet<String>("type");
    if (type != eventType) return false;

    var msgtype = content?.tryGet<String>("msgtype");

    if (eventKey != null && msgtype != eventKey) return false;

    return true;
  }

  @override
  void handleRequest(MatrixWidgetMessage message) async {
    var content = message.data.tryGetMap<String, dynamic>("content");

    if (content == null) return;

    var id = await runner.room!.matrixRoom.sendEvent(content, type: eventType);

    runner.messageTransport.send(message.createResponse(data: {
      "content": content,
      "event_id": id,
      "sender": runner.client.self!.identifier,
      "type": eventType,
    }, response: {
      "room_id": runner.room!.identifier,
      "event_id": id!,
    }));
  }
}
