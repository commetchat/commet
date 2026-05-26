import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';

class MatrixCapabilityTurnServers implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityTurnServers({required this.runner});

  static String name = "town.robin.msc3846.turn_servers";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityTurnServers(runner: runner));

  @override
  String toString() {
    return "Turn Servers";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    return message.action == "watch_turn_servers";
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    if (message.action == "watch_turn_servers") {
      runner.client.matrixClient.getTurnServer().then((config) async {
        runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
            action: "update_turn_servers",
            data: {
              "uris": config.uris,
              "username": config.username,
              "password": config.password
            }));
      });

      return message.createResponseObject();
    }

    return message.createResponseError(message: "Unimplemented");
  }
  
  @override
  void dispose() {
  }
}
