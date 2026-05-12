import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilitySendToDeviceEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;
  String? eventKey;

  MatrixCapabilitySendToDeviceEvent(
      {required this.runner, required this.eventType, this.eventKey});

  static String name = "org.matrix.msc3819.send.to_device";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilitySendToDeviceEvent(
          runner: runner, eventType: type!, eventKey: key));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "Send To Device event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action != "send_to_device") return false;
    if (message.api != "fromWidget") return false;
    var type = message.data.tryGet<String>("type");
    if (type != eventType) return false;

    return true;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var type = message.data.tryGet<String>("type")!;
    var encrypted = message.data.tryGet<bool>("encrypted") ?? false;

    var messages = message.data.tryGetMap<String, dynamic>("messages");

    Map<String, Map<String, Map<String, dynamic>>> map = Map();

    for (var pair in messages!.entries) {
      var mapB = pair.value as Map<dynamic, dynamic>;

      if (map[pair.key] == null) {
        map[pair.key] = {};
      }

      for (var pairB in mapB.entries) {
        if (map[pair.key]![pairB.key] == null) {
          map[pair.key]![pairB.key] = {};
        }

        var mapC = pairB.value as Map<String, dynamic>;

        map[pair.key]![pairB.key!] = mapC;
      }
    }

    final txn = runner.client.matrixClient.generateUniqueTransactionId();

    await runner.client.matrixClient.sendToDevice(type, txn, map);

    return message.createResponseObject();
  }
}
