import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';

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
