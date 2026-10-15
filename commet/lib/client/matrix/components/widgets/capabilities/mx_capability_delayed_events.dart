import 'dart:convert';

import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix_api_lite/matrix_api.dart' show RequestType;
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilitySendDelayedEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilitySendDelayedEvent({required this.runner});

  static const String name = "org.matrix.msc4157.send.delayed_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(name,
      (runner, type, key) => MatrixCapabilitySendDelayedEvent(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Send Delayed Event";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return false;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}

class MatrixCapabilityUpdateDelayedEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityUpdateDelayedEvent({required this.runner});

  static const String name = "org.matrix.msc4157.update_delayed_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) =>
          MatrixCapabilityUpdateDelayedEvent(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Update Delayed Event";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action != "org.matrix.msc4157.update_delayed_event")
      return false;

    if (message.data.containsKey("delay_id") == false) return false;
    if (message.data.containsKey("action") == false) return false;

    return true;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var delayId = message.data.tryGet<String>("delay_id");
    var action = message.data.tryGet<String>("action");
    if (delayId == null || action == null)
      throw UnsupportedError("Invalid request");

    final result = await runner.room!.matrixRoom.client.request(
        RequestType.POST,
        "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(delayId)}",
        contentType: "application/json",
        data: jsonEncode({"action": action}));

    Log.i("Got result from delayed event update ${result}");

    return message.createResponseObject(response: {});
  }

  @override
  void dispose() {}
}
