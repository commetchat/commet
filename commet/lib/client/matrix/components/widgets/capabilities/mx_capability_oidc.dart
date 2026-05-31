import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';

class MatrixCapabilityOIDC implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  MatrixCapabilityOIDC({required this.runner});

  static const String name = "m.oidc";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name, (runner, type, key) => MatrixCapabilityOIDC(runner: runner));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  @override
  String toString() {
    return "OIDC";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action == "get_openid") return true;

    return false;
  }

  Future<bool?>? currentConfirmationRequest;

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    if (message.action == "get_openid") {
      promptUserConfirmation(message.requestId);

      return message.createResponseObject(response: {"state": "request"});
    }

    throw UnimplementedError();
  }

  Future<void> promptUserConfirmation(String requestId) async {
    if (currentConfirmationRequest == null) {
      currentConfirmationRequest = currentConfirmationRequest =
          AdaptiveDialog.confirmation(navigator.currentContext!,
              title: "Allow ${runner.widgetId} to verify your user id");
    }

    var confirmed = await currentConfirmationRequest!;

    currentConfirmationRequest = null;

    if (confirmed == true) {
      var room = runner.room!;

      final token = await room.matrixRoom.client
          .requestOpenIdToken(room.matrixRoom.client.userID!, {});

      runner.messageTransport.send(runner.eventHandler
          .generateToWidgetEvent(action: "openid_credentials", data: {
        "state": "allowed",
        "original_request_id": requestId,
        "access_token": token.accessToken,
        "token_type": token.tokenType,
        "matrix_server_name": token.matrixServerName,
        "expires_in": token.expiresIn,
      }));

      return;
    }

    runner.messageTransport.send(runner.eventHandler.generateToWidgetEvent(
        action: "openid_credentials",
        data: {"state": "bloked", "original_request_id": requestId}));
  }

  @override
  void dispose() {}
}
