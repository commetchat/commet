import 'dart:async';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/src/utils/to_device_event.dart';

class MatrixCapabilityReceiveToDeviceEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;
  String? eventKey;

  StreamSubscription? sub;

  MatrixCapabilityReceiveToDeviceEvent(
      {required this.runner, required this.eventType, this.eventKey}) {
    sub = runner.client.matrixClient.onToDeviceEvent.stream
        .listen(onToDeviceMessage);
  }

  static String name = "org.matrix.msc3819.receive.to_device";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilityReceiveToDeviceEvent(
          runner: runner, eventType: type!, eventKey: key));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Receive To Device event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return false;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    return message.createResponseError(message: "Unimplemented");
  }

  void onToDeviceMessage(ToDeviceEvent event) {
    Log.i("Widget Capability received to device event");
    if (event.type != eventType) return;

    Log.i("Sending to device event to widget!");

    runner.messageTransport.send(runner.eventHandler
        .generateToWidgetEvent(action: "send_to_device", data: {
      "type": event.type,
      "sender": event.senderId,
      "encrypted": event.encryptedContent != null,
      "content": event.content
    }));
  }

  @override
  void dispose() {
    sub?.cancel();
  }
}
