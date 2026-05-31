import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';


class MatrixCapabilityTimeline implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String roomId;

  MatrixCapabilityTimeline({required this.runner, required this.roomId});

  static const String name = "org.matrix.msc2762.timeline";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) =>
          MatrixCapabilityTimeline(roomId: type!, runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Room Timeline";
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
  void dispose() {
  }
}
