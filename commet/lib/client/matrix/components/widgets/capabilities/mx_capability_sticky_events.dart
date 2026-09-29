import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';

class MatrixCapabilitySendStickyEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilitySendStickyEvent({required this.runner});

  static const String name = "org.matrix.msc4407.send.sticky_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(name,
      (runner, type, key) => MatrixCapabilitySendStickyEvent(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Send Sticky Event";
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

class MatrixCapabilityReceiveStickyEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityReceiveStickyEvent({required this.runner});

  static const String name = "org.matrix.msc4407.receive.sticky_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) =>
          MatrixCapabilityReceiveStickyEvent(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Receive Sticky Event";
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
